unit uConnectServer;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX, DBXJSON, StrUtils, ShellAPI;

type
  TConnectServer = class(TThread)
  private
    logStr: String;
  public
    update: Boolean;
  protected
    procedure Execute; override;
    procedure logThat;
  end;

implementation

uses uHelper, uMain, uUpdate;

{ TCheckUpdate }

procedure TConnectServer.Execute;
var
  i: Integer;
  Response: TStringStream;
  jObj: TJSONObject;
  My: TUpdate;

  AJSONValue: TJSONValue;
  Enum: TJSONPairEnumerator;
begin
  Synchronize(ASDPCUploader.preloaderShow);

  logStr :='Подключение к серверу..';
  Synchronize(logThat);

  try
    Response := TStringStream.Create;
    Google.Get(getUpdates, Response);
    jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
    Response.Free;
    appList := TAppList.Create(jObj.Get('items').JsonValue as TJSONArray);
    userApp := TUserApp.Create;

    if appList.Count > 0 then
    begin
      logStr := 'Проверка обновлений..';
      Synchronize(logThat);
    end;

    updateList := TStringList.Create;
    appList.checkUpdate(updateList);

    if (updateList.Count > 0) or (appList.RunOnceDate > appList.GetRunOnceDate) then
    begin
      if update then
      begin
        My := TUpdate.Create(True);
        My.Priority := tpNormal;
        My.FreeOnTerminate := True;
        My.Resume;
      end else
      begin
        logStr := 'На сервере есть обновления.';
        Synchronize(logThat);
        Synchronize(ASDPCUploader.preloaderHide);
      end;
    end else
    begin
      logStr := 'У вас установленна последняя версия приложения.';
      Synchronize(logThat);
      Synchronize(ASDPCUploader.exitCaption);
      Synchronize(ASDPCUploader.preloaderHide);
      if appRestart then
        ShellExecute(ASDPCUploader.Handle, 'open', PChar(userApp.appDir + userApp.appName), nil, nil, SW_SHOWNORMAL);
      if crLink then
      begin
        CoInitialize(nil);
        CreateLink(userApp.appDir + userApp.appName, GetDeskTopDir, True, False);
        CoUninitialize;
      end;
    end;
  except
    on E:Exception do
    begin
      Synchronize(ASDPCUploader.Log.Clear);
      logStr :='Ошибка подключения к серверу..';
      Synchronize(logThat);
      Synchronize(ASDPCUploader.exitCaption);
      Synchronize(ASDPCUploader.preloaderHide);
      Terminate;
    end;
  end;
end;

procedure TConnectServer.logThat;
begin
  ASDPCUploader.Log.Items.Add(logIndent + logStr);
end;

end.
