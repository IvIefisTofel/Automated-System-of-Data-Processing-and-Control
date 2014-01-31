unit uHelper;

interface

uses
  Classes, Windows, ActiveX, ShlObj, ShellAPI, SysUtils, ComObj, Forms, Google.OAuth,
  DateUtils, Generics.Collections, Registry, IniFiles, DBXJSON,
  uGoogle, uPasswords;

const
  dateDiff: TDateTime = 0.166666666666667; // 4 часа (разница времени с сервером)

{$IFDEF DEBUG}
  ASDPCFolder = '0B5D6JxRh4bpkczhaSURnMHUyTTA'; // ASDPC
{$ELSE}
  ASDPCFolder = '0B5D6JxRh4bpkYlJRYmNSN2FPRDg'; // Debug
{$ENDIF}
  getUpdates =
    'https://www.googleapis.com/drive/v2/files?q=%22' + ASDPCFolder + '%22+in+parents+and+trashed+%3D+false&fields=items(downloadUrl%2Cid%2CmodifiedDate%2Ctitle)';
  getRunOnce =
    'https://www.googleapis.com/drive/v2/files?q=%220B5D6JxRh4bpkak1GTEFNNTlGdFU%22+in+parents+and+title+%3D+%22RunOnce.exe%22&fields=items%2FdownloadUrl';

type
  TAppInfo = class
  private
    FId: String;
    FTitle: String;
    FModifiedDate: TDateTime;
    FDownloadUrl: String;
  public
    property Id: String read FId write FId;
    property Title: String read FTitle write FTitle;
    property ModifedDate: TDateTime read FModifiedDate write FModifiedDate;
    property DownloadUrl: String read FDownloadUrl write FDownloadUrl;
    constructor Create;
    destructor Destroy;
  end;

  TAppList = class(TList<TAppInfo>)
  private
    FRunOnce: TDateTime;
  public
    property RunOnceDate: TDateTime read FRunOnce;
    procedure Clear;
    procedure SetRunOnceDate;
    function GetRunOnceDate: TDateTime;
    procedure Parse(jsonArray: TJSONArray);
    procedure checkUpdate(var Strings: TStringList);
    constructor Create; overload;
    constructor Create(jsonArray: TJSONArray); overload;
    destructor Destroy;
  end;

  TUserApp = class
  const
    CAppName = 'ASDPC.exe';
  private
    FAppName: String;
    FAppDir: String;
    function checkAppExists: Boolean;
    function getAppDir: String;
  public
    function saveAppDirToRegistry: Boolean;
    property appDir: String read getAppDir write FAppDir;
    property appName: String read FAppName write FAppName;
    constructor Create;
    destructor Destroy;
  end;

  procedure self_deletion(const stop: Boolean = False);
  function GetDeskTopDir: string;
  function GetTempDir: String;
  function GetSystemDir: String;
  function CreateLink(FileName, DestDirectory: string; OverwriteExisting,
    AddNumberIfExists: Boolean): string;
  function ServerDateToDateTime(cServerDate: string): TDateTime;
  function DateTimeToServerDate(DateTime: TDateTime): string;

  function Wow64DisableWow64FsRedirection(x: Pointer): bool; stdcall;
    external 'Kernel32.dll' name 'Wow64DisableWow64FsRedirection';
  function Wow64RevertWow64FsRedirection(x: boolean): boolean; stdcall;
    external 'Kernel32.dll' name 'Wow64RevertWow64FsRedirection';

var
  appList: TAppList;
  updateList: TStringList;
  userApp: TUserApp;
  Google: TGoogle;

implementation

{ TAppInfo }

constructor TAppInfo.Create;
begin
  inherited Create;
end;

destructor TAppInfo.Destroy;
begin
  inherited;
end;

{ TAppList }

procedure TAppList.SetRunOnceDate;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  Reg.OpenKey('\Software\ASDPC', True);
  Reg.WriteDateTime('RunOnce', now);

  Reg.CloseKey;
  Reg.Free;
end;

function TAppList.GetRunOnceDate: TDateTime;
var
  Reg: TRegistry;
begin
  Result := StrToDateTime('30.01.1880');

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', True);
    if Reg.ValueExists('RunOnce') then
      Result := Reg.ReadDateTime('RunOnce');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

procedure TAppList.Parse(jsonArray: TJSONArray);
var
  i: Integer;
begin
  for i := 0 to jsonArray.Size - 1 do
  begin
    Add(TAppInfo.Create);
    Last.Id := ((jsonArray.Get(i) as TJSONObject).Get('id').JsonValue as TJSONString).Value;
    Last.Title := ((jsonArray.Get(i) as TJSONObject).Get('title').JsonValue as TJSONString).Value;
    Last.ModifedDate := ServerDateToDateTime(((jsonArray.Get(i) as TJSONObject).Get('modifiedDate').JsonValue as TJSONString).Value);
    Last.DownloadUrl := ((jsonArray.Get(i) as TJSONObject).Get('downloadUrl').JsonValue as TJSONString).Value;
  end;
end;

procedure TAppList.checkUpdate(var Strings: TStringList);
var
  i, j: Integer;
  Stream: TStream;
  Ini: TIniFile;
  dDrive, dCloud: TDateTime;
  allFiles: TStringList;
  fPath: String;
begin
  for i := Count - 1 downto 0 do
    if Items[i].Title = 'update.ini' then
    begin
      Stream := TMemoryStream.Create;
      try
        if Google.Get(Items[i].DownloadUrl, Stream) then
          TMemoryStream(Stream).SaveToFile(ExtractFilePath(Application.ExeName) + 'update.ini');
      finally
        Stream.Free;
      end;
      Break;
    end;

  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'update.ini');
  FRunOnce := StrToDateTime(Ini.ReadString('RunOnce', 'RunOnce', '30.01.1880'));

  allFiles := TStringList.Create;

  Ini.ReadSection('ASDPC', allFiles);

  Strings.Clear;
  if allFiles.Count > 0 then
  begin
    for i := 0 to allFiles.Count - 1 do
    begin
      if Copy(allFiles[i], 2, 8) =  'system32' then
      begin
        allFiles[i] := GetSystemDir + '\' + Ini.ReadString('ASDPC', allFiles[i], '');
        fPath := allFiles[i];
      end else
      begin
        allFiles[i] := Ini.ReadString('ASDPC', allFiles[i], '');
        fPath := userApp.appDir + allFiles[i];
      end;

      Wow64DisableWow64FsRedirection(nil);
      if FileExists(fPath) then
        dDrive := FileDateToDateTime(FileAge(fPath))
      else
        dDrive := StrToDate('30.01.1880');
      Wow64RevertWow64FsRedirection(True);

      for j := 0 to Count - 1 do
        if Items[j].Title = ExtractFileName(allFiles[i]) then
        begin
          dCloud := Items[j].ModifedDate;
          Break;
        end;
      if dCloud > dDrive then
        Strings.Add(allFiles[i]);
    end;
    userApp.appName := allFiles[0];
  end;

  Ini.Free;
  allFiles.Free;
end;

procedure TAppList.Clear;
var
  i: integer;
begin
  for i := Count - 1 downto 0 do
    Extract(Items[0]).Free;
  inherited Clear;
end;

constructor TAppList.Create;
begin
  inherited Create;
end;

constructor TAppList.Create(jsonArray: TJSONArray);
begin
  inherited Create;
  Parse(jsonArray);
end;

destructor TAppList.Destroy;
begin
  Clear;
  inherited;
end;

{ TUserApp }

constructor TUserApp.Create;
begin
  inherited Create;
  FAppDir := getAppDir;
  FAppName := CAppName;
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

  if (FAppName = '') or (FileExists(getAppDir + FAppName)) then
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

{ Helper }

procedure self_deletion(const stop: Boolean = False);
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
  if stop then
   halt;
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

function ServerDateToDateTime(cServerDate: string): TDateTime;
var
  Year, Mounth, Day, hours, Mins, Seconds: Word;
begin
  Year := StrToInt(Copy(cServerDate, 1, 4));
  Mounth := StrToInt(Copy(cServerDate, 6, 2));
  Day := StrToInt(Copy(cServerDate, 9, 2));
  hours := StrToInt(Copy(cServerDate, 12, 2));
  Mins := StrToInt(Copy(cServerDate, 15, 2));
  Seconds := StrToInt(Copy(cServerDate, 18, 2));
  Result := EncodeDateTime(Year, Mounth, Day, hours, Mins, Seconds, 0) +
    dateDiff;
end;

function DateTimeToServerDate(DateTime: TDateTime): string;
var
  Year, Mounth, Day, hours, Mins, Seconds, MSec: Word;
  aYear, aMounth, aDay, ahours, aMins, aSeconds, aMSec: string;
begin
  DecodeDateTime(DateTime - dateDiff, Year, Mounth, Day, hours, Mins, Seconds, MSec);
  aYear := IntToStr(Year);
  if Mounth < 10 then
    aMounth := '0' + IntToStr(Mounth)
  else
    aMounth := IntToStr(Mounth);
  if Day < 10 then
    aDay := '0' + IntToStr(Day)
  else
    aDay := IntToStr(Day);
  if hours < 10 then
    ahours := '0' + IntToStr(hours)
  else
    ahours := IntToStr(hours);
  if Mins < 10 then
    aMins := '0' + IntToStr(Mins)
  else
    aMins := IntToStr(Mins);
  if Seconds < 10 then
    aSeconds := '0' + IntToStr(Seconds)
  else
    aSeconds := IntToStr(Seconds);
  case MSec of
    0 .. 9:
      aMSec := '00' + IntToStr(MSec);
    10 .. 99:
      aMSec := '0' + IntToStr(MSec);
  else
    aMSec := IntToStr(MSec);
  end;
  Result := aYear + '-' + aMounth + '-' + aDay + 'T' + ahours + ':' + aMins +
    ':' + aSeconds + '.' + aMSec + 'Z';
end;

end.
