unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, ComObj, Graphics, Controls,
  Forms, Dialogs, Menus, ExtCtrls, StdCtrls, Buttons, ComCtrls, Registry,
  ShellApi,
  uGoogle, uHelper, uDataModule, uPreloader, uWatsNew, uTimeTable, uDrive,
  uAuth, uUpdater, uNewsLoader;

const
  gID = '57893525';

type
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
    procedure showNews;
    procedure ShowTaskBar;
    procedure checkUpdate(const showErrMgs: Boolean = False);
  end;

var
  Main: TASDPC_Main;

  Preloader: TPreloader;
  TimeTable: TTimeTable;
  TimeTableLoaded: Boolean = False;
  WatsNew: TWatsNew;
  WatsNewLoaded: Boolean = False;
  Drive: TDrive;
  Data: TData;
  Auth: TAuth;

  user: TUser;
  oldData, newData: TPostData;
  bClose: Boolean = False;

  Updater: TUpdater;
  NewsLoader: TNewsLoader;
  RepeatNews: TRepeatNews;

implementation

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
    Close;
  end;
end;

procedure TASDPC_Main.showNews;
begin
  Position := poScreenCenter;
  Show;
end;

procedure TASDPC_Main.ShowTaskBar;
begin
  if Assigned(TimeTable) and Assigned(Drive) then
    if (not TimeTable.Visible) and (not Drive.Visible) then
      ShowWindow(Application.Handle, SW_HIDE)
    else
      ShowWindow(Application.Handle, SW_NORMAL)
  else
    ShowWindow(Application.Handle, SW_NORMAL);
end;

procedure TASDPC_Main.checkUpdate(const showErrMgs: Boolean = False);
var
  CheckUpdate: TCheckUpdate;
begin
  CheckUpdate := TCheckUpdate.Create(True);
  CheckUpdate.Priority := tpNormal;
  CheckUpdate.showErrMsg := showErrMgs;
  CheckUpdate.FreeOnTerminate := True;
  CheckUpdate.Resume;
end;

procedure TASDPC_Main.FormCreate(Sender: TObject);
begin
  Google := TGoogle.Create;
  GoToGroup.OnClick := Data.GoVKClick;

  Updater := TUpdater.Create(True);
  Updater.Priority := tpNormal;
  Updater.FreeOnTerminate := False;

  NewsLoader := TNewsLoader.Create(True);
  NewsLoader.Priority := tpNormal;
  NewsLoader.FreeOnTerminate := False;

  RepeatNews := TRepeatNews.Create(True);
  RepeatNews.Priority := tpNormal;
  RepeatNews.FreeOnTerminate := False;
end;

procedure TASDPC_Main.FormShow(Sender: TObject);
begin
  RepeatNews.Suspend;
  SavePostDate(newData);

  if Post.CanFocus then
    Post.SetFocus;
  ShowTaskBar;
end;

procedure TASDPC_Main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := bClose;
  if CanClose then
  begin
    RepeatNews.Terminate;
    NewsLoader.Terminate;
    Updater.Terminate;
    Google.Free;
  end;
end;

procedure TASDPC_Main.OkClick(Sender: TObject);
begin
  Hide;
end;

end.
