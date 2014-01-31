unit uDriveViewer;

interface

uses
  Classes, SysUtils, CommCtrl, ComCtrls, DBXJSON, dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  Controls, uGoogle, uHelper;

type
  TDriveViewer = class(TThread)
  protected
    iCaption: String;
    iMimeType: String;
    iIndex: Integer;
    maxWidth: Integer;
  public
    currentDir: String;
  protected
    procedure Execute; override;
    procedure AddItem;
    procedure SetColumnWidth;
    procedure SortJSONArray;
    function getImageIndex(fName, mimeType: String): Integer;
  end;

implementation

uses uDrive;

{ TDriveViewer }

procedure TDriveViewer.Execute;
var
  Response: TStringStream;
  jObj: TJSONObject;
  i: Integer;
begin
  Synchronize(Drive.ListView1.Items.BeginUpdate);
  Synchronize(Drive.ListView1.Clear);
  Response := TStringStream.Create;
  Google.Get(StringReplace(getList, '{id}', currentDir,
    [rfReplaceAll, rfIgnoreCase]), Response);
  jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
  Response.Free;
  if Assigned(jObj) then
  begin
    jCurDir := jObj.Get('items').JsonValue as TJSONArray;
    Synchronize(SortJSONArray);
    if currentDir <> root then
    begin
      iCaption := '..';
      iMimeType := '';
      iIndex := -1;
      Synchronize(AddItem);
    end;
    for i := 0 to jCurDir.Size - 1 do
    begin
      jObj := jCurDir.Get(i) as TJSONObject;
      iCaption := (jObj.Get('title').JsonValue as TJSONString).Value;
      iMimeType := (jObj.Get('mimeType').JsonValue as TJSONString).Value;
      iIndex := i;
      Synchronize(AddItem);
    end;
    Synchronize(SetColumnWidth);
  end;
  Synchronize(Drive.ListView1.Items.EndUpdate);
end;

function TDriveViewer.getImageIndex(fName, mimeType: String): Integer;
var
  ext: String;
begin
  Result := 0;

  if mimeType = 'application/vnd.google-apps.folder' then
    Result := 1
  else
  begin
    ext := LowerCase(ExtractFileExt(fName));
    if (ext = '.docx') or (ext = '.doc') then
      Result := 2
    else if (ext = '.xls') or (ext = '.xslx') then
      Result := 3
    else if (ext = '.mdb') or (ext = '.accdb') then
      Result := 4
    else if (ext = '.ppt') or (ext = '.pptx') then
      Result := 5
    else if (ext = '.sln') or (ext = '.sdf') or (ext = '.suo') or (ext = '.pdb') or
      (ext = '.lik') or (ext = '.vcxproj') or (ext = '.filters') or (ext = '.obj') or
      (ext = '.idb') or (ext = '.tlog') or (ext = '.lastbuildstate') then
      Result := 6
    else if (ext = '.cpp') then
      Result := 7
    else if (ext = '.dpr') or (ext = '.dproj') then
      Result := 8
    else if (ext = '.pas') then
      Result := 9
    else if (ext = '.pdf') then
      Result := 10
    else if (ext = '.txt') then
      Result := 11
    else if (ext = '.rar') or (ext = '.zip') then
      Result := 12
    else if (ext = '.jpg') or (ext = '.jpeg') or (ext = '.png') or (ext = '.gif') then
      Result := 13
    else if (ext = '.cdw') or (ext = '.m3d') or (ext = '.spw') then
      Result := 14
    else if (ext = '.dia') then
      Result := 15;
  end;
end;

procedure TDriveViewer.AddItem;
begin
  with Drive.ListView1.Items.Add do
  begin
    if Drive.Canvas.TextWidth(iCaption) > maxWidth then
      maxWidth := Drive.Canvas.TextWidth(iCaption);
    Caption := iCaption;
    if Caption = '..' then
      ImageIndex := 1
    else
      ImageIndex := getImageIndex(iCaption, iMimeType);
    StateIndex := iIndex;
  end;
end;

procedure TDriveViewer.SetColumnWidth;
begin
  if maxWidth < 100 then
    maxWidth := 100;
  maxWidth := maxWidth + 40;
  Drive.ListView1.Perform(LVM_SETCOLUMNWIDTH, 0, maxWidth);
end;

procedure TDriveViewer.SortJSONArray;
var
  jArrTmp: TJSONArray;
  i, j: Integer;
  endIndex, tmp: Integer;
  arrIndex: array of Integer;
begin
  SetLength(arrIndex, jCurDir.Size);
  for i := 0 to jCurDir.Size - 1 do
    arrIndex[i] := i;

  endIndex := 0;
  for i := 0 to jCurDir.Size - 1 do
    if (((jCurDir.Get(arrIndex[i]) as TJSONObject).Get('mimeType').JsonValue as TJSONString).Value = 'application/vnd.google-apps.folder') then
    begin
      tmp := arrIndex[i];
      arrIndex[i] := arrIndex[endIndex];
      arrIndex[endIndex] := tmp;
      Inc(endIndex);
    end;

  for i := 1 to endIndex - 1 do
    for j := 1 to endIndex - 1 do
      if ((jCurDir.Get(arrIndex[j - 1]) as TJSONObject).Get('title').JsonValue as TJSONString).Value >
        ((jCurDir.Get(arrIndex[j]) as TJSONObject).Get('title').JsonValue as TJSONString).Value then
      begin
        tmp := arrIndex[j - 1];
        arrIndex[j - 1] := arrIndex[j];
        arrIndex[j] := tmp;
      end;


  Inc(endIndex);
  for i := endIndex to jCurDir.Size - 1 do
    for j := endIndex to jCurDir.Size - 1 do
      if ((jCurDir.Get(arrIndex[j - 1]) as TJSONObject).Get('title').JsonValue as TJSONString).Value >
        ((jCurDir.Get(arrIndex[j]) as TJSONObject).Get('title').JsonValue as TJSONString).Value then
      begin
        tmp := arrIndex[j - 1];
        arrIndex[j - 1] := arrIndex[j];
        arrIndex[j] := tmp;
      end;


  jArrTmp := TJSONArray.Create;
  for i := 0 to jCurDir.Size - 1 do
    jArrTmp.AddElement(jCurDir.Get(arrIndex[i]) as TJSONObject);

  jCurDir := jArrTmp as TJSONArray;
end;

end.
