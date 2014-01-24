unit uCheckUpdate;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, ActiveX, ShellAPI;

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

uses uMain, uASDP_Update;

{ TCheckUpdate }

procedure TCheckUpdate.Execute;
var
  Str: String;
  updateList: TStringList;
  haveUpdates: Boolean;
begin
  try
    WebDAV := TWebDAVSend.Create;
    userApp := TUserApp.Create;
    Resources := TWDResourceList.Create;
    updateList := TStringList.Create;

    Resources.Clear;
    Str := WebDAV.PROPFIND(1, '');
    if Length(Trim(Str)) > 0 then
    begin
      CoInitialize(nil);
      ParseResources(Str);
      CoUninitialize;

      Resources.checkUpdate(updateList);
    end;

    Str := userApp.appDir;
    haveUpdates := updateList.Count > 0;
    WebDAV.Destroy;
    Resources.Destroy;
    userApp.Destroy;
    updateList.Destroy;

    if haveUpdates and FileExists(Str + 'ASDPC_Updater.exe') then
    begin
      ShellExecute(Main.Handle, nil, PChar(Str + 'ASDPC_Updater.exe'), 'updateAndRestart', PChar(Str), SW_NORMAL);
      bClose := True;
      Synchronize(Main.Close);
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
  if Copy(msg, 1, 7) = 'Ошибка!' then
    MessageDlg(msg, mtWarning, [mbOk], 0)
  else
    MessageDlg(msg, mtCustom, [mbOk], 0)
end;

end.
