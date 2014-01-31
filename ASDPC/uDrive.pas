unit uDrive;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, StdCtrls, Buttons, ComCtrls, DBXJSON, Math,
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

const
  HeightDiff = 28;

var
  Drive: TDrive;
  currentDir: String;
  jCurDir: TJSONArray;

implementation

uses uTimeTable, uMain, uDataModule, uDriveViewer;

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

    Google.GetFile(url, fName, pBarParams, True, nil);
  end;
end;

end.
