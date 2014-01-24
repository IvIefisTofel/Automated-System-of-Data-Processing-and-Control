unit uThread;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX, ShellAPI;

type
  TMyThread = class(TThread)
  private
    logStr: String;
  protected
    procedure Execute; override;
    procedure logThat;
  end;

implementation

uses uMain, uASDP_Update;

{ TMyThread }

procedure TMyThread.Execute;
var
  fPath: string;
  i, j: integer;
  Stream: TStream;
  dDrive, dCloud: TDateTime;
  updateList: TStringList;
  Ini: TIniFile;
  download: Boolean;
begin
  Synchronize(Main.preloaderShow);

  try
    if Resources.Count > 0 then
    begin
      logStr := 'Проверка обновлений..';
      Synchronize(logThat);

      updateList := TStringList.Create;
      Resources.checkUpdate(updateList);

      if updateList.Count > 0 then
      begin
        for j := 0 to updateList.Count - 1 do
        begin
          logStr := 'Обновление файла "' + updateList[j] + '"..';
          Synchronize(logThat);

          if Pos(updateList[j], ':') = 0 then
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
              Exit;
            end;
          end;
          Wow64RevertWow64FsRedirection(True);

          for i := 0 to Resources.Count - 1 do
            if ExtractFileName(updateList[j]) = Resources[i].DisplayName then
            begin
              Stream := TMemoryStream.Create;
              try
                if WebDAV.Get(Resources[i].Href, Stream) then
                  TMemoryStream(Stream).SaveToFile(fPath);
              finally
                Stream.Free;

              end;
            end;
        end;
        updateList.Free;
        if appRestart then
          ShellExecute(Main.Handle, 'open', PChar(userApp.appDir + userApp.appName), nil, nil, SW_SHOWNORMAL);
        logStr := 'Обновление завершено.';
        Synchronize(logThat);
      end else
      begin
        logStr := 'У вас установленна последняя версия приложения.';
        Synchronize(logThat);
      end;
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

procedure TMyThread.logThat;
begin
  Main.Log.Items.Add(logIndent + logStr);
end;

end.
