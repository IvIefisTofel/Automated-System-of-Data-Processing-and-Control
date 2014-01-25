unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.ComCtrls, ComObj,
  uDataModule, uCheckUpdate, uHelper;

type
  TUser = record
    access_token: String;
    userId: String;
  end;

  TMain = class(TForm)
    Ok: TBitBtn;
    GoToGroup: TLabel;
    Post: TRichEdit;
    Avatar: TImage;
    UserInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure OkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
  public
    procedure showNews(const id: Integer = -1);
    procedure checkUpdate(const showErrMgs: Boolean = False);
  end;

var
  Main: TMain;
  Response: string;
  user: TUser;
  oldData, newData: TPostData;
  HaveRead: Boolean = False;
  bClose: Boolean = False;

implementation

uses Registry, ShellApi, lib, ssl_openssl, httpsend;

{$R *.dfm}

procedure TMain.showNews(const id: Integer);
begin
  Position := poScreenCenter;
  Show;
end;

procedure TMain.checkUpdate(const showErrMgs: Boolean = False);
var
  updater: TCheckUpdate;
begin
  updater := TCheckUpdate.Create(True);
  updater.Priority := tpNormal;
  updater.force := showErrMgs;
  updater.FreeOnTerminate := True;
  updater.Resume;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  Data.AuthShow.Enabled := true;
end;

procedure TMain.FormShow(Sender: TObject);
begin
  if not HaveRead then
  begin
    HaveRead := True;
    Data.SaveDate(newData);
  end;

  if Post.CanFocus then
    Post.SetFocus;
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := bClose;
end;

procedure TMain.OkClick(Sender: TObject);
begin
  Main.Hide;
end;

end.
