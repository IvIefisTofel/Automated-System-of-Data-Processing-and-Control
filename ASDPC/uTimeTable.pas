unit uTimeTable;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, AdvObj, BaseGrid, AdvGrid, StdCtrls, Buttons,
  Registry, DBXJSON,
  uHelper, uDataModule;

const
  getTimeTable = 'https://www.googleapis.com/drive/v2/files/0B5D6JxRh4bpkOTg1eDhNTFBEYU0?fields=downloadUrl%2CmodifiedDate';

type
  TTimeTable = class(TForm)
    Grid: TAdvStringGrid;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure GridGetCellColor(Sender: TObject; ARow, ACol: Integer;
      AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
    procedure GridGetAlignment(Sender: TObject; ARow, ACol: Integer;
      var HAlign: TAlignment; var VAlign: TVAlignment);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    FShowAfterUpdate: Boolean;
  public
    procedure LoadCSV;
    procedure updateTimeTable(const ShowAfterUpdate: Boolean = False);
    procedure OnLoadFile(Stream: TMemoryStream);
  end;

var
  TimeTable: TTimeTable;
  TimeTableLoaded: Boolean = False;

implementation

uses uDrive;

{$R *.dfm}

procedure TTimeTable.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_NORMAL);
end;

procedure TTimeTable.FormHide(Sender: TObject);
begin
  if not Drive.Visible then
    ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TTimeTable.GridGetAlignment(Sender: TObject; ARow,
  ACol: Integer; var HAlign: TAlignment; var VAlign: TVAlignment);
begin
  VAlign := vtaCenter;
end;

procedure TTimeTable.GridGetCellColor(Sender: TObject; ARow,
  ACol: Integer; AState: TGridDrawState; ABrush: TBrush; AFont: TFont);
begin
  if Grid.IsNode(ARow) then
  begin
    afont.Style := [fsBold, fsUnderline];
    abrush.color := clHighlight;
    afont.Color := clWhite;
  end else
    abrush.color := clSkyBlue;
end;

procedure TTimeTable.BitBtn1Click(Sender: TObject);
begin
  Grid.ExpandAll;
end;

procedure TTimeTable.BitBtn2Click(Sender: TObject);
begin
  Grid.ContractAll;
end;

procedure TTimeTable.LoadCSV;
var
  i: Integer;
begin
  TimeTable.Grid.LoadFromCSV('cache\timetable.csv');

  TimeTable.Grid.AutoSizeColumns(False,10);
  TimeTable.Grid.InsertCols(0,1);
  TimeTable.Grid.ColWidths[0] := 20;

  i := 1;
  while i < TimeTable.Grid.RowCount do
  begin
    if TimeTable.Grid.Cells[2, i] = '' then
    begin
      TimeTable.Grid.MergeCells(0, i - 1, 1, 2);
      TimeTable.Grid.MergeCells(2, i - 1, 1, 2);
      TimeTable.Grid.MergeCells(3, i - 1, 1, 2);
      if TimeTable.Grid.Cells[4, i] = '' then
        TimeTable.Grid.MergeCells(4, i - 1, 1, 2);
    end else
    if TimeTable.Grid.Cells[4, i] = '' then
    begin
      TimeTable.Grid.MergeCells(3, i, 2, 1);
      TimeTable.Grid.Alignments[3, i] := taCenter;
    end;
    i := i + 1;
  end;
  TimeTable.Grid.Group(1);
  TimeTable.Grid.ContractAll;

  TimeTableLoaded := True;
end;

procedure TTimeTable.OnLoadFile(Stream: TMemoryStream);
var
  Reg: TRegistry;
begin
  if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'cache') then
    CreateDir(ExtractFilePath(ParamStr(0)) + 'cache');

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey('\Software\ASDPC',True);
  Reg.WriteDateTime('TimeTable', now);
  Reg.CloseKey;
  Reg.Free;

  Stream.SaveToFile('cache\timetable.csv');

  LoadCSV;

  if FShowAfterUpdate then
    TimeTable.Show;
end;

procedure TTimeTable.updateTimeTable(const ShowAfterUpdate: Boolean);
var
  UpdateDate: TDateTime;
  jObj: TJSONObject;
  Reg: TRegistry;
  Response: TStringStream;
begin
  if not TimeTableLoaded then
  begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;

    Reg.OpenKey('\Software\ASDPC',True);
    if Reg.ValueExists('TimeTable') then
      UpdateDate := Reg.ReadDateTime('TimeTable')
    else
      UpdateDate := StrToDateTime('30.01.1880');

    Response := TStringStream.Create;
    Google.Get(getTimeTable, Response);
    jObj := (TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject);
    Response.Clear;
    if (ServerDateToDateTime((jObj.Get('modifiedDate').JsonValue as TJSONString).Value) > UpdateDate)
      or not FileExists('cache\timetable.csv') then
    begin
      FShowAfterUpdate := ShowAfterUpdate;
      Google.Get((jObj.Get('downloadUrl').JsonValue as TJSONString).Value, OnLoadFile);

      Response.Free;
      Reg.CloseKey;
      Reg.Free;
    end else
    begin
      LoadCSV;
      Response.Free;
      Reg.CloseKey;
      Reg.Free;

      if ShowAfterUpdate then
        TimeTable.Show;
    end;
  end else
  if ShowAfterUpdate then
    TimeTable.Show;
end;

end.
