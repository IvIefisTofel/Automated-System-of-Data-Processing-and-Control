unit uWatsNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls,
  Registry, DBXJSON,
  uHelper, uDataModule, uTimeTable, uDrive;

const
  getWatsNew = 'https://www.googleapis.com/drive/v2/files/0B5D6JxRh4bpkakltVzk0dDFpdnM?fields=downloadUrl%2CmodifiedDate';

type
  TWatsNew = class(TForm)
    News: TRichEdit;
    LabelWatsNew: TLabel;
    Ok: TBitBtn;
    procedure OkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    procedure LoadWatsNew;
    procedure updateWatsNew(const ShowAfterUpdate: Boolean = False);
    procedure OnLoadFile(Stream: TMemoryStream);
  end;

var
  WatsNew: TWatsNew;
  UpdateDate: TDateTime;
  WatsNewLoaded: Boolean = False;
  Stream: TStream;

implementation

{$R *.dfm}

procedure TWatsNew.FormShow(Sender: TObject);
begin
  if (not TimeTable.Visible) and (not Drive.Visible) then
    ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TWatsNew.OkClick(Sender: TObject);
begin
  WatsNew.Close;
end;

procedure TWatsNew.LoadWatsNew;
begin
  WatsNew.News.Lines.LoadFromFile('cache\watsnew.txt');

  WatsNewLoaded := True;
end;

procedure TWatsNew.OnLoadFile(Stream: TMemoryStream);
var
  Reg: TRegistry;
begin
  if not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'cache') then
    CreateDir(ExtractFilePath(ParamStr(0)) + 'cache');

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey('\Software\ASDPC',True);
  Reg.WriteDateTime('WatsNew', now);
  Reg.CloseKey;
  Reg.Free;

  Stream.SaveToFile('cache\watsnew.txt');

  LoadWatsNew;
  WatsNewLoaded := True;

  WatsNew.Show;
end;

procedure TWatsNew.updateWatsNew(const ShowAfterUpdate: Boolean);
var
  jObj: TJSONObject;
  Reg: TRegistry;
  Response: TStringStream;
begin
  if not WatsNewLoaded then
  begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;

    Reg.OpenKey('\Software\ASDPC',True);
    if Reg.ValueExists('WatsNew') then
      UpdateDate := Reg.ReadDateTime('WatsNew')
    else
      UpdateDate := StrToDateTime('30.01.1880');

    Response := TStringStream.Create;
    Google.Get(getWatsNew, Response);
    jObj := (TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject);
    Response.Clear;
    if (ServerDateToDateTime((jObj.Get('modifiedDate').JsonValue as TJSONString).Value) > UpdateDate)
      or not FileExists('cache\watsnew.txt') then
    begin
      Google.Get((jObj.Get('downloadUrl').JsonValue as TJSONString).Value, OnLoadFile);

      Response.Free;
      Reg.CloseKey;
      Reg.Free;
    end else
    begin
      LoadWatsNew;

      Response.Free;
      Reg.CloseKey;
      Reg.Free;

      if ShowAfterUpdate then
        WatsNew.Show;
    end;
  end else
  if ShowAfterUpdate then
    WatsNew.Show;
end;

end.
