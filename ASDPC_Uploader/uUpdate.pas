unit uUpdate;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX, ShellAPI;

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
  updateList: TStringList;
  dDrive, dCloud: TDateTime;
  Ini: TIniFile;
  download: Boolean;
begin
  Synchronize(Main.preloaderShow);

  try
    updateList := TStringList.Create;
    appList.checkUpdate(updateList);

    if updateList.Count > 0 then
    begin
      for j := 0 to updateList.Count - 1 do
      begin
        logStr := 'Обновление файла "' + ExtractFileName(updateList[j]) + '"..';
        Synchronize(logThat);

        if Pos(':', updateList[j]) <> 0 then
          fPath := updateList[j]
        else
          fPath := userApp.appDir + updateList[j];

        Wow64DisableWow64FsRedirection(nil);
        if FileExists(fPath) then
        begin
          if not DeleteFile(fPath) then
          begin
            logStr := 'Ошибка обновления файла "' + updateList[j] + '". Фйал используется.';
            Synchronize(logThat);
            Synchronize(Main.preloaderHide);
            if Main.UpdateBtn.CanFocus then
              Synchronize(Main.UpdateBtn.SetFocus);
            Wow64RevertWow64FsRedirection(True);
            Exit;
          end;
        end;
        Wow64RevertWow64FsRedirection(True);

        for i := 0 to appList.Count - 1 do
          if ExtractFileName(updateList[j]) = appList[i].Title then
          begin
            Stream := TMemoryStream.Create;
            try
              if GoogleGet(appList[i].DownloadUrl, Stream) then
                TMemoryStream(Stream).SaveToFile(fPath);
            finally
              Stream.Free;

            end;
          end;
      end;
      updateList.Free;
      if appRestart then
        ShellExecute(Main.Handle, 'open', PChar(userApp.appDir + userApp.appName), nil, nil, SW_SHOWNORMAL);
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
      Synchronize(Main.exitCaption);
      Synchronize(Main.preloaderHide);
      if Main.UpdateBtn.CanFocus then
        Synchronize(Main.UpdateBtn.SetFocus);
    end;
  end;

  Synchronize(Main.exitCaption);
  Synchronize(Main.preloaderHide);
  if Main.UpdateBtn.CanFocus then
    Synchronize(Main.UpdateBtn.SetFocus);
end;

procedure TUpdate.logThat;
begin
  Main.Log.Items.Add(logIndent + logStr);
end;

end.
