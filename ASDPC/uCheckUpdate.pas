unit uCheckUpdate;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, ActiveX, ShellAPI,
  StrUtils, DBXJSON;

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

  AJSONValue: TJSONValue;
  Enum: TJSONPairEnumerator;

  updateList: TStringList;
  haveUpdates: Boolean;
begin
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

    userApp := TUserApp.Create;
    appList := TAppList.Create;
    updateList := TStringList.Create;

    appList.checkUpdate(updateList);

    appDir := userApp.appDir;
    haveUpdates := updateList.Count > 0;
    userApp.Destroy;
    updateList.Destroy;

    if haveUpdates and FileExists(appDir + 'ASDPC_Updater.exe') then
    begin
      ShellExecute(Main.Handle, nil, PChar(appDir + 'ASDPC_Updater.exe'), 'update restart', PChar(appDir), SW_NORMAL);
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
