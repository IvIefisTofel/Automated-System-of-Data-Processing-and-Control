unit uASDP_Update;

interface

uses
  httpsend, synacode, ssl_openssl, synautil, xmldoc, xmlintf, Registry,
  Winapi.Windows, Winapi.ShellAPI, Winapi.ShlObj, Winapi.ActiveX, System.Classes,
  System.SysUtils, System.Win.ComObj, System.DateUtils, Generics.Collections,
  Vcl.Forms, IniFiles, Vcl.Dialogs, uPasswords;

const
  cWebDAVServer = 'https://webdav.yandex.ru/';
  logIndent = ' ';

type
  TWDResource = class
  private
    FHref: string;
    FStatusCode: integer;
    FContentLength: int64;
    FCreationDate: TDateTime;
    FLastmodified: TDateTime;
    FDisplayName: string;
    FContentType: string;
    FCollection: Boolean;
  public
    property StatusCode: integer read FStatusCode;
    property ContentLength: int64 read FContentLength;
    property CreationDate: TDateTime read FCreationDate;
    property Lastmodified: TDateTime read FLastmodified;
    property DisplayName: string read FDisplayName;
    property ContentType: string read FContentType;
    property Href: string read FHref;
    property Collection: Boolean read FCollection;
  end;

  TWDResourceList = class(TList<TWDResource>)
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure checkUpdate(var Strings: TStringList);
  end;

  TWebDAVSend = class
  const
    FLogin = myYandexLogin;
    FPassword = myYandexPassword;
  private
    FHTTP: THTTPSend;
    FToken: AnsiString;
    function EncodeUTF8URI(const URI: string): string;
    function GetRequestURL(const Element: string;
      EncodePath: Boolean = True): string;
  public
    constructor Create;
    destructor Destroy; override;
    function PROPFIND(Depth: integer; const Element: String): string;
    function Get(const ElementHref: string; var Response: TStream): Boolean;
  end;

  TUserApp = class
  private
    FAppName: String;
    FAppDir: String;
    function checkAppExists: Boolean;
    function getAppDir: String;
  public
    function saveAppDirToRegistry: Boolean;
    property isInstalled: Boolean read checkAppExists;
    property appDir: String read getAppDir write FAppDir;
    property appName: String read FAppName write FAppName;
    constructor Create;
    destructor Destroy;
  end;

  procedure self_deletion;
  function GetDeskTopDir: string;
  function GetTempDir: String;
  function GetSystemDir: String;
  function CreateLink(FileName, DestDirectory: string; OverwriteExisting,
    AddNumberIfExists: Boolean): string;
  function TzSpecificLocalTimeToSystemTime(lpTimeZoneInformation:
    PTimeZoneInformation; var lpLocalTime, lpUniversalTime: TSystemTime): Bool;
    stdcall; external kernel32 name 'TzSpecificLocalTimeToSystemTime';
  function Wow64DisableWow64FsRedirection(x: Pointer): bool; stdcall;
    external 'Kernel32.dll' name 'Wow64DisableWow64FsRedirection';
  function Wow64RevertWow64FsRedirection(x: boolean): boolean; stdcall;
    external 'Kernel32.dll' name 'Wow64RevertWow64FsRedirection';
  function UTCToSystemTime(UTC: TDateTime): TDateTime;
  function ISODateTime2UTC(const AValue: string; ADateOnly: Boolean = false): TDateTime;
  procedure ParseResources(const AXMLStr: string);

var
  WebDAV: TWebDAVSend;
  Resources: TWDResourceList;
  userApp: TUserApp;
  appCanReatart: Boolean = False;
  appRestart: Boolean = False;

implementation

resourcestring
  rsPropfindError = 'Ошибка при выполнении запроса PROPFIND';

procedure self_deletion;
const
  batName = 'del.bat';
var
  batFile: TextFile;
begin
  AssignFile(batFile, ExtractFilePath(ParamStr(0)) + batName);
  Rewrite(batFile);
  Writeln(batFile, '@echo off');
  Writeln(batFile, ':try');
  Writeln(batFile, 'del /q "' + ExtractFileName(ParamStr(0)) + '"');
  Writeln(batFile, 'if exist "' + ExtractFileName(ParamStr(0)) + '" goto try');
  Writeln(batFile, 'del /q "' + batName + '"');
  CloseFile(batFile);
  ShellExecute(Application.Handle, 'open', batName, nil, nil, SW_HIDE);
//  halt;
end;

function GetDeskTopDir: string;
var
  SpecialDir: PItemIdList;
begin
    SetLength(result, MAX_PATH);
    SHGetSpecialFolderLocation(Application.Handle, CSIDL_DESKTOP, SpecialDir);
    SHGetPathFromIDList(SpecialDir, PChar(Result));
    SetLength(result, lStrLen(PChar(Result)));
end;

function GetTempDir: String;
var
  path: array[0..MAX_PATH] of WideChar;
begin
  GetTempPath(MAX_PATH, path);
  Result := path;
end;

function GetSystemDir: String;
var
  path: array[0..MAX_PATH] of WideChar;
begin
  GetSystemDirectory(path, MAX_PATH);
  Result := path;
end;

function CreateLink(FileName, DestDirectory: string; OverwriteExisting,
  AddNumberIfExists: Boolean): string;

var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WFileName: WideString;
  X: INTEGER;
begin
  Result := '';
  if (FileExists(FileName) = FALSE) or (DirectoryExists(DestDirectory) = FALSE)
    then
    exit;
  MyObject := CreateComObject(CLSID_SHELLLINK);
  MyPFile := MyObject as IPersistFile;
  MySLink := MyObject as IShellLink;
  with MySLink do
  begin
    SetArguments('');
    SetPath(PChar(FileName));
    SetWorkingDirectory(PChar(ExtractFilePath(FileName)));
  end;

  if DestDirectory[length(DestDirectory)] <> '\' then
    DestDirectory := DestDirectory + '\';
  WFileName := DestDirectory + Copy(ExtractFileName(FileName), 1, Length(ExtractFileName(FileName)) - 4) + '.lnk';
  if (FileExists(WFileName)) then
  begin
    if (OverwriteExisting = FALSE) and (AddNumberIfExists = TRUE) then
    begin
      X := 0;
      repeat
        X := X + 1;
        WFileName := DestDirectory + Copy(ExtractFileName(FileName), 1, Length(ExtractFileName(FileName)) - 4)
          + IntToStr(X) + '.lnk';
      until FileExists(WFileName) = FALSE;
      MyPFile.Save(PWChar(WFileName), FALSE);
      Result := WFileName;
    end;
    if OverwriteExisting = TRUE then
    begin
      MyPFile.Save(PWChar(WFileName), FALSE);
      Result := WFileName;
    end;
  end
  else
  begin
    MyPFile.Save(PWChar(WFileName), FALSE);
    Result := WFileName;
  end;
end;

function SystemTimeToUTC(Sys: TDateTime): TDateTime;
var
  TimeZoneInf: _TIME_ZONE_INFORMATION;
  SysTime, LocalTime: TSystemTime;
begin
  if GetTimeZoneInformation(TimeZoneInf) < $FFFFFFFF then
  begin
    DatetimetoSystemTime(Sys, SysTime);
    if TzSpecificLocalTimeToSystemTime(@TimeZoneInf, SysTime, LocalTime) then
      result := SystemTimeToDateTime(LocalTime)
    else
      result := Sys;
  end
  else
    result := Sys;
end;

function UTCToSystemTime(UTC: TDateTime): TDateTime;
var
  TimeZoneInf: _TIME_ZONE_INFORMATION;
  UTCTime, LocalTime: TSystemTime;
begin
  if GetTimeZoneInformation(TimeZoneInf) < $FFFFFFFF then
  begin
    DatetimetoSystemTime(UTC, UTCTime);
    if SystemTimeToTzSpecificLocalTime(@TimeZoneInf, UTCTime, LocalTime) then
    begin
      result := SystemTimeToDateTime(LocalTime);
    end
    else
      result := UTC;
  end
  else
    result := UTC;
end;

function ISODateTime2UTC(const AValue: string; ADateOnly: Boolean = false): TDateTime;
var
  i, Len: integer;
  DD, MM, YY: Word;
  HH, MN, SS, ZZ: Word;
  HH1, MN1: integer;
  TimeOffsetSign: Char;
begin
  Len := length(AValue);
  YY := StrToIntDef(copy(AValue, 1, 4), 0);
  i := 5;
  if (i <= Len) and (AValue[i] = '-') then
    inc(i);
  MM := StrToIntDef(copy(AValue, i, 2), 0);
  inc(i, 2);
  if (i <= Len) and (AValue[i] = '-') then
    inc(i);
  DD := StrToIntDef(copy(AValue, i, 2), 0);
  inc(i, 2);
  HH := 0;
  MN := 0;
  SS := 0;
  ZZ := 0;
  if not ADateOnly and (i <= Len) and (AValue[i] = 'T') then
  begin
    inc(i);
    HH := StrToIntDef(copy(AValue, i, 2), 0);
    inc(i, 2);
    if (i <= Len) and CharInSet(AValue[i], [':', '0' .. '5']) then
    begin
      if AValue[i] = ':' then
        inc(i);
      MN := StrToIntDef(copy(AValue, i, 2), 0);
      inc(i, 2);
      if (i <= Len) and CharInSet(AValue[i], [':', '0' .. '5']) then
      begin
        if AValue[i] = ':' then
          inc(i);
        SS := StrToIntDef(copy(AValue, i, 2), 0);
        inc(i, 2);
        if (i <= Len) and (AValue[i] = '.') then
        begin
          inc(i);
          ZZ := StrToIntDef(copy(AValue, i, 3), 0);
          inc(i, 3);
        end;
      end;
    end;
  end;
  result := EncodeDateTime(YY, MM, DD, HH, MN, SS, ZZ);
  if ADateOnly then
    Exit;
  if (i <= Len) and CharInSet(AValue[i], ['Z', '+', '-']) then
  begin
    if AValue[i] <> 'Z' then
    begin
      TimeOffsetSign := AValue[i];
      inc(i);
      HH1 := StrToIntDef(copy(AValue, i, 2), 0);
      inc(i, 2);
      if (i <= Len) and CharInSet(AValue[i], [':', '0' .. '5']) then
      begin
        if AValue[i] = ':' then
          inc(i);
        MN1 := StrToIntDef(copy(AValue, i, 2), 0);
      end
      else
        MN1 := 0;
      if TimeOffsetSign = '+' then
      begin
        HH1 := -HH1;
        MN1 := -MN1;
      end;
      result := IncHour(result, HH1);
      result := IncMinute(result, MN1);
    end;
  end
  else
    result := SystemTimeToUTC(result);
end;

procedure ParseResources(const AXMLStr: string);
var
  xmldoc: IXMLDocument;
  ResponseNode, ChildNode, PropNodeChild, PropertyNode: IXMLNode;
  s, su, Value: string;
begin
  xmldoc := TXMLDocument.Create(nil);
  try
    xmldoc.LoadFromXML(AXMLStr);
    if not xmldoc.IsEmptyDoc then
    begin
      ResponseNode := xmldoc.DocumentElement.ChildNodes.First;
      while Assigned(ResponseNode) do
      begin
        Resources.Add(TWDResource.Create);
        ChildNode := ResponseNode.ChildNodes.First;
        while Assigned(ChildNode) do
        begin
          if ChildNode.NodeName = 'd:href' then
            Resources.Last.FHref := ChildNode.Text
          else if ChildNode.NodeName = 'd:propstat' then
          begin
            PropNodeChild := ChildNode.ChildNodes.First;
            while Assigned(PropNodeChild) do
            begin
              if PropNodeChild.NodeName = 'd:status' then
              begin
                Value := PropNodeChild.Text;
                s := Trim(SeparateRight(Value, ' '));
                su := Trim(SeparateLeft(s, ' '));
                Resources.Last.FStatusCode := StrToIntDef(su, 0);
              end
              else if PropNodeChild.NodeName = 'd:prop' then
              begin
                PropertyNode := PropNodeChild.ChildNodes.First;
                while Assigned(PropertyNode) do
                begin
                  if PropertyNode.NodeName = 'd:creationdate' then
                    Resources.Last.FCreationDate :=
                      UTCToSystemTime(ISODateTime2UTC(PropertyNode.Text))
                  else if PropertyNode.NodeName = 'd:displayname' then
                    Resources.Last.FDisplayName := Utf8ToAnsi(PropertyNode.Text)
                  else if PropertyNode.NodeName = 'd:getcontentlength' then
                    Resources.Last.FContentLength := PropertyNode.NodeValue
                  else if PropertyNode.NodeName = 'd:getlastmodified' then
                    Resources.Last.FLastmodified :=
                      DecodeRfcDateTime(PropertyNode.Text)
                  else if PropertyNode.NodeName = 'd:resourcetype' then
                    Resources.Last.FCollection :=
                      PropertyNode.ChildNodes.Count > 0;
                  PropertyNode := PropertyNode.NextSibling;
                end;
              end;
              PropNodeChild := PropNodeChild.NextSibling;
            end;
          end;
          ChildNode := ChildNode.NextSibling;
        end;
        ResponseNode := ResponseNode.NextSibling;
      end;
    end;
  finally
    xmldoc := nil;
  end;
end;

{ TWebDAVSend }

constructor TWebDAVSend.Create;
begin
  inherited;
  FHTTP := THTTPSend.Create;
  FToken := EncodeBase64(FLogin + ':' + FPassword);
end;

destructor TWebDAVSend.Destroy;
begin
  FHTTP.Free;
  inherited;
end;

function TWebDAVSend.EncodeUTF8URI(const URI: string): string;
var
  i: integer;
  Char: AnsiChar;
begin
  result := '';
  for i := 1 to length(URI) do
  begin
    if not(URI[i] in URLFullSpecialChar) then
    begin
      for Char in UTF8String(URI[i]) do
        result := result + '%' + IntToHex(Ord(Char), 2)
    end
    else
      result := result + URI[i];
  end;
end;

function TWebDAVSend.Get(const ElementHref: string;
  var Response: TStream): Boolean;
var
  URL: string;
begin
  if not Assigned(Response) then
    Exit;
  URL := GetRequestURL(ElementHref, false);
  with FHTTP do
  begin
    Headers.Clear;
    Document.Clear;
    Headers.Add('Authorization: Basic ' + FToken);
    Headers.Add('Accept: */*');
    if HTTPMethod('GET', URL) then
    begin
      result := ResultCode = 200;
      if not result then
        raise Exception.Create(IntToStr(ResultCode) + ' ' + ResultString)
      else
        Document.SaveToStream(Response);
    end
    else
      raise Exception.Create(rsPropfindError + ' ' + ResultString);
  end;
end;

function TWebDAVSend.GetRequestURL(const Element: string;
  EncodePath: Boolean): string;
var
  URI: string;
begin
  if length(Element) > 0 then
  begin
    URI := Element;
    if URI[1] = '/' then
      Delete(URI, 1, 1);
    if EncodePath then
      result := cWebDAVServer + EncodeUTF8URI(URI)
    else
      result := cWebDAVServer + URI
  end
  else
    result := cWebDAVServer;
end;

function TWebDAVSend.PROPFIND(Depth: integer; const Element: String): string;
begin
  with FHTTP do
  begin
    Headers.Clear;
    Document.Clear;
    Headers.Add('Authorization: Basic ' + FToken);
    Headers.Add('Depth: ' + IntToStr(Depth));
    Headers.Add('Accept: */*');
    if HTTPMethod('PROPFIND', GetRequestURL(Element)) then
      result := ReadStrFromStream(Document, Document.Size)
    else
      raise Exception.Create(rsPropfindError + ' ' + ResultString);
  end;
end;

{ TWDResourceList }

constructor TWDResourceList.Create;
begin
  inherited Create;
end;

destructor TWDResourceList.Destroy;
begin
  Clear;
  inherited;
end;

procedure TWDResourceList.Clear;
var
  i: integer;
begin
  for i := Count - 1 downto 0 do
    Extract(Items[0]).Free;
  inherited Clear;
end;

procedure TWDResourceList.checkUpdate(var Strings: TStringList);
var
  i, j, l: Integer;
  Stream: TStream;
  Ini: TIniFile;
  dDrive, dCloud: TDateTime;
  allFiles: TStringList;
  fPath: String;
begin
  for i := 0 to Count - 1 do
    if Items[i].DisplayName = 'update.ini' then
    begin
      Stream := TMemoryStream.Create;
      try
        if WebDAV.Get(Resources[i].Href, Stream) then
          TMemoryStream(Stream).SaveToFile(ExtractFilePath(Application.ExeName) + 'update.ini');
      finally
        Stream.Free;
      end;

      Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'update.ini');
      allFiles := TStringList.Create;

      Ini.ReadSection('ASDPC', allFiles);

      Strings.Clear;
      if allFiles.Count > 0 then
      begin
        for j := 0 to allFiles.Count - 1 do
        begin
          if Copy(allFiles[j], 2, 8) =  'system32' then
          begin
            allFiles[j] := GetSystemDir + '\' + Ini.ReadString('ASDPC', allFiles[j], '');
            fPath := allFiles[j];
          end else
          begin
            allFiles[j] := Ini.ReadString('ASDPC', allFiles[j], '');
            fPath := userApp.appDir + allFiles[j];
          end;

          Wow64DisableWow64FsRedirection(nil);
          if FileExists(fPath) then
            dDrive := FileDateToDateTime(FileAge(fPath))
          else
            dDrive := StrToDate('30.01.1880');
          Wow64RevertWow64FsRedirection(True);

          for l := 0 to Resources.Count - 1 do
            if Items[l].DisplayName = ExtractFileName(allFiles[j]) then
            begin
              dCloud := Items[l].Lastmodified;
              Break;
            end;
          if dCloud > dDrive then
            Strings.Add(allFiles[j]);
        end;
        userApp.appName := allFiles[0];
        appCanReatart := True;
      end;

      Ini.Free;
      allFiles.Free;
    end;
end;

{ TUserApp }

constructor TUserApp.Create;
begin
  inherited Create;
end;

destructor TUserApp.Destroy;
begin
  inherited Destroy;
end;

function TUserApp.checkAppExists: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;

  try
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.KeyExists('\Software\ASDPC') then
    begin
      Reg.OpenKey('\Software\ASDPC', False);
      if Reg.ValueExists('appDir') then
        Result := True;
    end;

    Reg.CloseKey;
    Reg.Free;
  except
    on E:Exception do
      Result := False;
  end;
end;

function TUserApp.getAppDir: String;
var
  Reg: TRegistry;
begin
  Result := '';

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    if Reg.ValueExists('appDir') then
      Result := Reg.ReadString('appDir');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

function TUserApp.saveAppDirToRegistry: Boolean;
var
  Reg: TRegistry;
  fPath: String;
begin
  Result := False;

  if (FAppName = '') or (getAppDir <> '') then
    Exit;

  try
    fPath := ExtractFilePath(Application.ExeName);

    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;

    Reg.OpenKey('\Software\ASDPC', True);
    Reg.WriteString('appDir', fPath);

    Reg.CloseKey;
    Reg.Free;

    Result := True;
  except
    on E:Exception do
      Result := False;
  end;
end;

end.
