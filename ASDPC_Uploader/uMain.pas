unit uMain;

interface

uses
  Windows, Messages, ShellApi, SysUtils, Variants, Classes, Generics.Collections,
  Graphics, Controls, Forms, Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls,
  uHelper, uConnectServer, uDataModule, uUpdate, GIFImg, PNGImage;

const
  logIndent = ' ';

type
  TMain = class(TForm)
    Preloader: TImage;
    UpdateBtn: TBitBtn;
    Icon: TImage;
    Log: TListBox;
    procedure UpdateBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure preloaderShow;
    procedure preloaderHide;
    procedure exitCaption;
  end;

var
  Main: TMain;
  appRestart: Boolean = False;
  crLink: Boolean = False;
  dateDiff: TDateTime;

implementation

{$R *.dfm}

{ TMain }

procedure TMain.preloaderShow;
begin
  UpdateBtn.Enabled := False;
  Preloader.Show;
  Icon.Hide;
end;

procedure TMain.preloaderHide;
begin
  UpdateBtn.Enabled := True;
  Preloader.Hide;
  Icon.Show;
end;

procedure TMain.exitCaption;
begin
  UpdateBtn.Caption := 'Выход';
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Res: TResourceStream;
  Gif: TGIFImage;
begin
  Res:=TResourceStream.Create(Hinstance, 'Preloader', 'IMAGE');
  Gif := TGIFImage.Create;
  Gif.LoadFromStream(Res);
  Res.Free;

  Gif.Animate := true;
  Preloader.Picture.Assign(Gif);
  Gif.Free;
end;

procedure TMain.FormShow(Sender: TObject);
var
  My: TConnectServer;
  update: Boolean;
  i: Integer;
begin
  update := False;
  if ParamCount <> 0 then
    for i := 1 to ParamCount do
    begin
      if ParamStr(i) = 'update' then
        update := True
      else if ParamStr(i) = 'restart' then
        appRestart := True
      else if ParamStr(i) = 'createLink' then
        crLink := True;
    end;

  My := TConnectServer.Create(True);
  My.Priority := tpNormal;
  My.FreeOnTerminate := True;
  My.update := update;
  My.Resume;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  userApp.saveAppDirToRegistry;
  userApp.Free;

  appList.Free;

  self_deletion;
end;

procedure TMain.UpdateBtnClick(Sender: TObject);
var
  My: TUpdate;
begin
  if UpdateBtn.Caption = 'Выход' then
    Main.Close;

  My := TUpdate.Create(True);
  My.Priority := tpNormal;
  My.FreeOnTerminate := True;
  My.Resume;
end;

end.
