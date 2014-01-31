unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, ComObj, Graphics, Controls,
  Forms, Dialogs, Menus, ExtCtrls, StdCtrls, Buttons, ComCtrls,
  uDataModule, uCheckUpdate, uGoogle, uHelper, uDrive;

type
  TUser = record
    access_token: String;
    userId: String;
  end;

  TASDPC_Main = class(TForm)
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
    procedure CopyData(var Msg: TWMCopyData); message WM_COPYDATA;
  public
    procedure showNews(const id: Integer = -1);
    procedure checkUpdate(const showErrMgs: Boolean = False);
  end;

var
  ASDPC_Main: TASDPC_Main;
  Response: string;
  user: TUser;
  oldData, newData: TPostData;
  HaveRead: Boolean = False;
  bClose: Boolean = False;

implementation

uses uTimeTable, Registry, ShellApi, lib, ssl_openssl, httpsend;

{$R *.dfm}

procedure TASDPC_Main.CopyData(var Msg: TWMCopyData);
var
  command: string;
begin
  command := PChar(Msg.CopyDataStruct.lpData);
  SetForegroundWindow(Handle);
  if command = 'exit' then
  begin
    bClose := True;
    ASDPC_Main.Close;
  end;
end;

procedure TASDPC_Main.showNews(const id: Integer);
begin
  Position := poScreenCenter;
  Show;
end;

procedure TASDPC_Main.checkUpdate(const showErrMgs: Boolean = False);
var
  updater: TCheckUpdate;
begin
  updater := TCheckUpdate.Create(True);
  updater.Priority := tpNormal;
  updater.force := showErrMgs;
  updater.FreeOnTerminate := True;
  updater.Resume;
end;

procedure TASDPC_Main.FormCreate(Sender: TObject);
begin
  Google := TGoogle.Create;
  Data.AuthShow.Enabled := true;
end;

procedure TASDPC_Main.FormShow(Sender: TObject);
begin
  if not HaveRead then
  begin
    HaveRead := True;
    Data.SaveDate(newData);
  end;

  if Post.CanFocus then
    Post.SetFocus;
  if (not TimeTable.Visible) and (not Drive.Visible) then
    ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TASDPC_Main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := bClose;
  if CanClose then
    Google.Free;
end;

procedure TASDPC_Main.OkClick(Sender: TObject);
begin
  ASDPC_Main.Hide;
end;

end.
