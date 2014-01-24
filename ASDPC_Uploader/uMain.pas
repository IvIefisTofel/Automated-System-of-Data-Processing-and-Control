unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.ExtCtrls, ShellApi,
  uThread, uASDP_Update, uCheckUpdate, Vcl.Imaging.pngimage;

type
  TMain = class(TForm)
    Preloader: TImage;
    UpdateBtn: TBitBtn;
    Icon: TImage;
    Log: TListBox;
    procedure UpdateBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
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

procedure TMain.FormShow(Sender: TObject);
var
  startThread: Boolean;
  My: TCheckUpdate;
begin
  startThread := False;
  if ParamCount <> 0 then
  begin
    if ParamStr(1) = 'update' then
      startThread := True;
    if ParamStr(1) = 'updateAndRestart' then
    begin
      startThread := True;
      appRestart := True;
    end;
  end else
    UpdateBtn.Enabled := True;

  My := TCheckUpdate.Create(True);
  My.Priority := tpNormal;
  My.FreeOnTerminate := True;
  My.startThread := startThread;
  My.Resume;
end;

procedure TMain.UpdateBtnClick(Sender: TObject);
var
  My: TMyThread;
begin
  if UpdateBtn.Caption = 'Выход' then
    Main.Close;

  My := TMyThread.Create(True);
  My.Priority := tpNormal;
  My.FreeOnTerminate := True;
  My.Resume;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  userApp.saveAppDirToRegistry;
  userApp.Destroy;

  Resources.Free;
  WebDAV.Free;

  self_deletion;
end;

end.
