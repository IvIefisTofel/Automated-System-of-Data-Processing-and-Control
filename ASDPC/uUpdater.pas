unit uUpdater;

interface

uses
  Windows, SysUtils, Classes, Dialogs, ActiveX, ShellAPI, Forms,
  StrUtils, DBXJSON, uGoogle, uHelper;

type
  TUpdater = class(TThread)
  protected
    procedure Execute; override;
  end;

  TCheckUpdate = class(TThread)
  private
    msg: String;
    Response: TStringStream;
  public
    showErrMsg: Boolean;
  protected
    procedure Execute; override;
    procedure GetUpdateList;
    procedure ShowMsg;
  end;

implementation

uses uMain;

{ TUpdater }

procedure TUpdater.Execute;
var
  CheckUpdate: TCheckUpdate;
begin
  Sleep(10000);
  while not Terminated do
  begin
    CheckUpdate := TCheckUpdate.Create(True);
    CheckUpdate.Priority := tpNormal;
    CheckUpdate.showErrMsg := False;
    CheckUpdate.FreeOnTerminate := True;
    CheckUpdate.Resume;
    Sleep(3600000);
  end;
end;

{ TCheckUpdate }

procedure TCheckUpdate.Execute;
var
  appDir: String;

  updateList: TStringList;
  haveUpdates: Boolean;
begin
  try
    userApp := TUserApp.Create;
    updateList := TStringList.Create;

    Response := TStringStream.Create;
    Synchronize(GetUpdateList);
    appList := TAppList.Create((TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject).Get('items').JsonValue as TJSONArray);
    Response.Free;

    appList.checkUpdate(updateList);

    appDir := userApp.appDir;
    haveUpdates := (updateList.Count > 0) or (appList.RunOnceDate > appList.GetRunOnceDate);
    userApp.Destroy;
    updateList.Destroy;

    if haveUpdates and FileExists(appDir + 'ASDPC_Updater.exe') then
    begin
      ShellExecute(Application.Handle, nil, PChar(appDir + 'ASDPC_Updater.exe'), 'update restart', PChar(appDir), SW_NORMAL);
      bClose := True;
      Synchronize(Main.Close);
    end else if showErrMsg then
    begin
      if haveUpdates then
        msg := 'Ошибка!'#13#10'Updater не был найден'
      else
        msg := 'У вас установленна последняя версия программы';
      Synchronize(ShowMsg);
    end;
  except
    on E:Exception do
      Terminate;
  end;
end;

procedure TCheckUpdate.GetUpdateList;
begin
  Google.Get(getUpdates, Response);
end;

procedure TCheckUpdate.ShowMsg;
begin
  ShowWindow(Application.Handle, SW_NORMAL);
  if Copy(msg, 1, 7) = 'Ошибка!' then
    MessageDlg(msg, mtWarning, [mbOk], 0)
  else
    MessageDlg(msg, mtCustom, [mbOk], 0);
  Main.ShowTaskBar;
end;

end.
