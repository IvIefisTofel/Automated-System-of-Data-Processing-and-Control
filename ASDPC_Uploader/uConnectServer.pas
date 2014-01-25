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

uses uHelper, uMain, uUpdate, uDataModule;

{ TCheckUpdate }

procedure TConnectServer.Execute;
var
  i: Integer;
  Response: TStringStream;
  jObj: TJSONObject;
  My: TUpdate;

  AJSONValue: TJSONValue;
  Enum: TJSONPairEnumerator;

  updateList: TStringList;
begin
  Synchronize(Main.preloaderShow);

  logStr :='Подключение к серверу..';
  Synchronize(logThat);

  try
    AJSONValue := TJSONObject.ParseJSONValue(json);
    if Assigned(AJSONValue) then
    try
      Enum := TJSONObject(AJSONValue).GetEnumerator;
      try
        while Enum.MoveNext do
          with Enum.Current do
            case AnsiIndexStr(JsonString.Value, cFilePairs) of
              0: Data.gOAuth.ClientSecret := JsonValue.Value;
              1: Data.gOAuth.RedirectURI := JsonValue.Value;
              2: Data.gOAuth.State := JsonValue.Value;
              3: Data.gOAuth.LoginHint := JsonValue.Value;
              4: Data.gOAuth.TokenInfo.Parse(TJSONObject(JsonValue).ToString);
            end;
        Data.gOAuth.RefreshToken;
      finally
        Enum.Free
      end;
    finally
      AJSONValue.Free;
    end;

    Response := TStringStream.Create;
    GoogleGet(getUpdates, Response);
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

    if updateList.Count > 0 then
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
        Synchronize(Main.preloaderHide);
      end;
    end else
    begin
      logStr := 'У вас установленна последняя версия приложения.';
      Synchronize(logThat);
      Synchronize(Main.exitCaption);
      Synchronize(Main.preloaderHide);
      if appRestart then
        ShellExecute(Main.Handle, 'open', PChar(userApp.appDir + userApp.appName), nil, nil, SW_SHOWNORMAL);
      if crLink then
      begin
        CoInitialize(nil);
        CreateLink(userApp.appDir + userApp.appName, GetDeskTopDir, True, False);
        CoUninitialize;
      end;
    end;
    updateList.Free;
  except
    on E:Exception do
    begin
      Synchronize(Main.Log.Clear);
      logStr :='Ошибка подключения к серверу..';
      Synchronize(logThat);
      Synchronize(Main.exitCaption);
      Synchronize(Main.preloaderHide);
    end;
  end;
end;

procedure TConnectServer.logThat;
begin
  Main.Log.Items.Add(logIndent + logStr);
end;

end.
