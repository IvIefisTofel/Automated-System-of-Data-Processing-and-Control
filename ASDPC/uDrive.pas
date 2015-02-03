unit uDrive;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, StdCtrls, Buttons, ComCtrls, DBXJSON, Math, CommCtrl,
  uHelper, uGoogle;

const
  root = '0B5D6JxRh4bpkN1RXbUtpTGptZlk';
  getList = 'https://www.googleapis.com/drive/v2/files?maxResults=100&q="{id}"+in+parents&fields=items(downloadUrl%2CfileSize%2Cid%2CmimeType%2Ctitle)';
  getParent = 'https://www.googleapis.com/drive/v2/files/{id}?fields=parents%2Fid';

type
  TDrive = class(TForm)
    ImageList1: TImageList;
    BitBtn1: TBitBtn;
    ListView1: TListView;
    Label1: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView1DblClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
  protected
    procedure WMGetSysCommand(var Message :TMessage); message WM_SYSCOMMAND;
  private
    { Private declarations }
  public
    procedure NextFolder;
    procedure BeforePBarCreate(Sender: TObject);
    procedure AfterPBarDestroy(Top, Left, Height, Width: Integer);
  end;

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

const
  HeightDiff = 28;

var
  currentDir: String;
  jCurDir: TJSONArray;
  curFileSize: Int64;

implementation

uses uMain;

{$R *.dfm}

procedure TDrive.WMGetSysCommand(var Message: TMessage);
begin
  if (Message.wParam = SC_MINIMIZE) then
    Application.Minimize
  else
    Inherited;
end;

procedure TDrive.FormShow(Sender: TObject);
var
  lDir: TDriveViewer;
begin
  ShowWindow(Application.Handle, SW_NORMAL);

  currentDir := root;
  lDir := TDriveViewer.Create(True);
  lDir.Priority := tpNormal;
  lDir.currentDir := currentDir;
  lDir.FreeOnTerminate := True;
  lDir.Resume;
end;

procedure TDrive.FormHide(Sender: TObject);
begin
  if not TimeTable.Visible then
    ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TDrive.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if ListView1.ItemIndex <> -1 then
    if ListView1.Items[ListView1.ItemIndex].StateIndex <> -1 then
      if (((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('mimeType').JsonValue as TJSONString).Value <> 'application/vnd.google-apps.folder') then
      begin
        Label1.Caption := ((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('title').JsonValue as TJSONString).Value + ' (' +
          FloatToStr(RoundTo(StrToFloat(((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('fileSize').JsonValue as TJSONString).Value) / 1024, -2)) + ' Kb)';
        curFileSize := StrToInt64(((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('fileSize').JsonValue as TJSONString).Value);
        BitBtn1.Tag := ListView1.ItemIndex;
        BitBtn1.Enabled := True;
      end else
      begin
        Label1.Caption := ((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('title').JsonValue as TJSONString).Value;
        BitBtn1.Enabled := False;
      end;
end;

procedure TDrive.NextFolder;
var
  lDir: TDriveViewer;
  Response: TStringStream;
  jObj: TJSONObject;
begin
  if ListView1.ItemIndex <> -1 then
  begin
    Label1.Caption := '';
    BitBtn1.Enabled := False;
    if ListView1.Items[ListView1.ItemIndex].StateIndex = -1 then
    begin
      Response := TStringStream.Create;
      Google.Get(StringReplace(getParent, '{id}', currentDir,
        [rfReplaceAll, rfIgnoreCase]), Response);
      jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
      Response.Free;
      if Assigned(jObj) then
      begin
        currentDir := (((jObj.Get('parents').JsonValue as TJSONArray).Get(0) as TJSONObject).Get('id').JsonValue as TJSONString).Value;      lDir := TDriveViewer.Create(True);
        lDir := TDriveViewer.Create;
        lDir.Priority := tpNormal;
        lDir.currentDir := currentDir;
        lDir.FreeOnTerminate := True;
        lDir.Resume;
      end;
    end else
    if ((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('mimeType').JsonValue as TJSONString).Value = 'application/vnd.google-apps.folder' then
    begin
      currentDir := ((jCurDir.Get(ListView1.Items[ListView1.ItemIndex].StateIndex) as TJSONObject).Get('id').JsonValue as TJSONString).Value;
      lDir := TDriveViewer.Create;
      lDir.Priority := tpNormal;
      lDir.currentDir := currentDir;
      lDir.FreeOnTerminate := True;
      lDir.Resume;
    end;
  end;
end;

procedure TDrive.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
    NextFolder;
end;

procedure TDrive.ListView1DblClick(Sender: TObject);
begin
  NextFolder;
end;

procedure TDrive.BeforePBarCreate(Sender: TObject);
begin
  ListView1.Height := ListView1.Height - HeightDiff;
end;

procedure TDrive.AfterPBarDestroy(Top, Left, Height, Width: Integer);
var
  i: Integer;
begin
  for i := 0 to Drive.ComponentCount - 1 do
  begin
    if Drive.Components[i] is TProgressBar then
      if (Drive.Components[i] as TProgressBar).Top < Top then
        (Drive.Components[i] as TProgressBar).Top := (Drive.Components[i] as TProgressBar).Top + HeightDiff;
  end;

  ListView1.Height := ListView1.Height + HeightDiff;
end;

procedure TDrive.BitBtn1Click(Sender: TObject);
var
  url, fExt, fName: String;
  pBarParams: TPBarParams;
begin
  url := ((jCurDir.Get(ListView1.Items[BitBtn1.Tag].StateIndex) as TJSONObject).Get('downloadUrl').JsonValue as TJSONString).Value;
  fName := ((jCurDir.Get(ListView1.Items[BitBtn1.Tag].StateIndex) as TJSONObject).Get('title').JsonValue as TJSONString).Value;
  fExt := ExtractFileExt(fName);
  Data.Save.Filter := '|*' + fExt;
  Data.Save.FileName := fName;
  if Data.Save.Execute then
  begin
    if ExtractFileExt(Data.Save.FileName) = '' then
      fName := Data.Save.FileName + fExt
    else if ExtractFileExt(Data.Save.FileName) <> fExt then
      fName := Data.Save.FileName + fExt
    else
      fName := Data.Save.FileName;

    pBarParams.AOwner := Drive;
    pBarParams.Parent := Drive;
    pBarParams.Anchors := [akLeft, akRight, akBottom];
    pBarParams.Top := ListView1.Top + ListView1.Height - HeightDiff + 8;
    pBarParams.Left := ListView1.Left;
    pBarParams.Height := 20;
    pBarParams.Width := ListView1.Width;
    pBarParams.BeforeCreate := BeforePBarCreate;
    pBarParams.AfterDestroy := AfterPBarDestroy;
    pBarParams.Size := curFileSize;

    Google.GetFile(url, fName, pBarParams, True, nil);
  end;
end;

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
