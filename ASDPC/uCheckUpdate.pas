unit uCheckUpdate;

interface

uses
  Windows, SysUtils, Classes, Dialogs, ActiveX, ShellAPI, Forms,
  StrUtils, DBXJSON, uTimeTable;

type
  TCheckUpdate = class(TThread)
  private
    msg: String;
  public
    force: Boolean;
  protected
    procedure Execute; override;
    procedure ShowMsg;
  end;

implementation

uses uMain, uDataModule, uHelper;

{ TCheckUpdate }

procedure TCheckUpdate.Execute;
var
  appDir: String;
  Response: TStringStream;

  updateList: TStringList;
  haveUpdates: Boolean;
begin
  try
    userApp := TUserApp.Create;
    updateList := TStringList.Create;

    Response := TStringStream.Create;
    Google.Get(getUpdates, Response);
    appList := TAppList.Create((TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject).Get('items').JsonValue as TJSONArray);
    Response.Free;

    appList.checkUpdate(updateList);

    appDir := userApp.appDir;
    haveUpdates := (updateList.Count > 0) or (appList.RunOnceDate > appList.GetRunOnceDate);
    userApp.Destroy;
    updateList.Destroy;

    if haveUpdates and FileExists(appDir + 'ASDPC_Updater.exe') then
    begin
      ShellExecute(ASDPC_Main.Handle, nil, PChar(appDir + 'ASDPC_Updater.exe'), 'update restart', PChar(appDir), SW_NORMAL);
      bClose := True;
      Synchronize(ASDPC_Main.Close);
    end else if force then
    begin
      if haveUpdates then
        msg := 'Ошибка!'#13#10'Updater не был найден'
      else
        msg := 'У вас установленна последняя версия программы';
      Synchronize(ShowMsg);
    end;
  except
    on E:Exception do
      Exit;
  end;
end;

procedure TCheckUpdate.ShowMsg;
begin
  ShowWindow(Application.Handle, SW_NORMAL);
  if Copy(msg, 1, 7) = 'Ошибка!' then
    MessageDlg(msg, mtWarning, [mbOk], 0)
  else
    MessageDlg(msg, mtCustom, [mbOk], 0);
  if not TimeTable.Visible then
    ShowWindow(Application.Handle, SW_HIDE);
end;

end.
