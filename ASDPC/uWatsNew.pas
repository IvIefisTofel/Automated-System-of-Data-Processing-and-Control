unit uWatsNew;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls,
  Registry, DBXJSON,
  uHelper;

const
  getWatsNew = 'https://www.googleapis.com/drive/v2/files/0B5D6JxRh4bpkakltVzk0dDFpdnM?fields=downloadUrl%2CmodifiedDate';

type
  TLoader = class(TThread)
  private
    Response: TStringStream;
  public
    FShowAfterUpdate: Boolean;
  protected
    procedure Execute; override;
    procedure LoadWatsNew;
    procedure WatsNewShow;
  end;

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
    procedure OnLoadFile(Stream: TStream);
  end;

var
  UpdateDate: TDateTime;
  Stream: TStream;

implementation

uses uMain;

{$R *.dfm}

procedure TWatsNew.FormShow(Sender: TObject);
begin
  Main.ShowTaskBar;
end;

procedure TWatsNew.OkClick(Sender: TObject);
begin
  WatsNew.Close;
end;

procedure TWatsNew.LoadWatsNew;
begin
  WatsNew.News.Lines.LoadFromFile(saveTo + '\watsnew.txt');

  WatsNewLoaded := True;
end;

procedure TWatsNew.OnLoadFile(Stream: TStream);
var
  Reg: TRegistry;
begin
  if not DirectoryExists(saveTo) then
    CreateDir(saveTo);

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.OpenKey('\Software\ASDPC',True);
  Reg.WriteDateTime('WatsNew', now);
  Reg.CloseKey;
  Reg.Free;

  (Stream as TMemoryStream).SaveToFile(saveTo + '\watsnew.txt');

  LoadWatsNew;
  WatsNewLoaded := True;

  WatsNew.Show;
end;

procedure TWatsNew.updateWatsNew(const ShowAfterUpdate: Boolean);
var
  Loader: TLoader;
begin
  Loader := TLoader.Create(True);
  Loader.Priority := tpNormal;
  Loader.FShowAfterUpdate := ShowAfterUpdate;
  Loader.FreeOnTerminate := True;
  Loader.Resume;
end;

{ TLoader }

procedure TLoader.Execute;
var
  jObj: TJSONObject;
  Reg: TRegistry;
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
    Synchronize(LoadWatsNew);
    jObj := (TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject);
    Response.Clear;
    if (ServerDateToDateTime((jObj.Get('modifiedDate').JsonValue as TJSONString).Value) > UpdateDate)
      or not FileExists(saveTo + '\watsnew.txt') then
    begin
      Google.Get((jObj.Get('downloadUrl').JsonValue as TJSONString).Value, WatsNew.OnLoadFile);

      Response.Free;
      Reg.CloseKey;
      Reg.Free;
    end else
    begin
      Synchronize(WatsNew.LoadWatsNew);

      Response.Free;
      Reg.CloseKey;
      Reg.Free;

      Synchronize(WatsNewShow);
    end;
  end else
    Synchronize(WatsNewShow);
end;

procedure TLoader.LoadWatsNew;
begin
  Google.Get(getWatsNew, Response);
end;

procedure TLoader.WatsNewShow;
begin
  if FShowAfterUpdate then
    WatsNew.Show;
end;

end.
