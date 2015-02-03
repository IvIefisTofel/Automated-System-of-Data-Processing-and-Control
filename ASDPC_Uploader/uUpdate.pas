unit uUpdate;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX, ShellAPI, DBXJSON;

const
  RunOnceStartParam = '70D07BD1-8A42-43CE-986B-B57EA1F5CA77';

type
  TUpdate = class(TThread)
  private
    logStr: String;
  protected
    procedure Execute; override;
    procedure logThat;
  end;

implementation

uses uMain, uHelper;

{ TMyThread }

procedure TUpdate.Execute;
var
  fPath: string;
  i, j: integer;
  Stream: TStream;
  Response: TStringStream;
  dDrive, dCloud: TDateTime;
  Ini: TIniFile;
  download: Boolean;
begin
  Synchronize(ASDPCUploader.preloaderShow);

  try
    if (updateList.Count > 0) or (appList.RunOnceDate > appList.GetRunOnceDate) then
    begin
      for j := 0 to updateList.Count - 1 do
      begin
        logStr := 'Обновление файла "' + ExtractFileName(updateList[j]) + '"..';
        Synchronize(logThat);

        fPath := userApp.appDir + updateList[j];

        if FileExists(fPath) then
        begin
          if not DeleteFile(fPath) then
          begin
            logStr := 'Ошибка обновления файла "' + updateList[j] + '". Фйал используется.';
            Synchronize(logThat);
            Synchronize(ASDPCUploader.preloaderHide);
            if ASDPCUploader.UpdateBtn.CanFocus then
              Synchronize(ASDPCUploader.UpdateBtn.SetFocus);
            Exit;
          end;
        end;

        for i := 0 to appList.Count - 1 do
        begin
          if ExtractFileName(updateList[j]) = appList[i].Title then
          begin
            Stream := TMemoryStream.Create;
            try
              if Google.Get(appList[i].DownloadUrl, Stream) then
                TMemoryStream(Stream).SaveToFile(fPath);
            finally
              Stream.Free;
            end;
            Break;
          end;
        end;
      end;
      updateList.Free;

      if appList.RunOnceDate > appList.GetRunOnceDate then
      begin
        logStr := 'Загрузка RunOnce приложения.';
        Synchronize(logThat);

        Response := TStringStream.Create;
        Google.Get(getRunOnce, Response);
        Stream := TMemoryStream.Create;
        try
          if Google.Get(((((TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as
              TJSONObject).Get('items').JsonValue as TJSONArray).Get(0) as
              TJSONObject).Get('downloadUrl').JSonValue as TJSONString).Value, Stream) then
            TMemoryStream(Stream).SaveToFile(userApp.appDir + 'RunOnce.exe');
        finally
          Stream.Free;
          logStr := 'Запуск RunOnce приложения.';
          appList.SetRunOnceDate;
          Synchronize(logThat);
          ShellExecute(ASDPCUploader.Handle, 'open', PChar(userApp.appDir + 'RunOnce.exe'), RunOnceStartParam, PChar(userApp.appDir), SW_SHOWNORMAL);
        end;
        Response.Free;
      end;

      if appRestart then
        ShellExecute(ASDPCUploader.Handle, 'open', PChar(userApp.appDir + userApp.appName), nil, nil, SW_SHOWNORMAL);
      if crLink then
      begin
        CoInitialize(nil);
        CreateLink(userApp.appDir + userApp.appName, GetDeskTopDir, True, False);
        CoUninitialize;
      end;
      logStr := 'Обновление завершено.';
      Synchronize(logThat);
    end else
    begin
      logStr := 'У вас установленна последняя версия приложения.';
      Synchronize(logThat);
    end;
  except
    on E:Exception do
    begin
      logStr := 'Ошибка обновления..';
      Synchronize(logThat);
      Synchronize(ASDPCUploader.exitCaption);
      Synchronize(ASDPCUploader.preloaderHide);
      if ASDPCUploader.UpdateBtn.CanFocus then
        Synchronize(ASDPCUploader.UpdateBtn.SetFocus);
      Terminate;
    end;
  end;

  Synchronize(ASDPCUploader.exitCaption);
  Synchronize(ASDPCUploader.preloaderHide);
  if ASDPCUploader.UpdateBtn.CanFocus then
    Synchronize(ASDPCUploader.UpdateBtn.SetFocus);
end;

procedure TUpdate.logThat;
begin
  ASDPCUploader.Log.Items.Add(logIndent + logStr);
end;

end.
