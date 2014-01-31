unit uThread;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX;

type
  TMyThread = class(TThread)
  private
    logMsg: String;
  public
    fInstallPath: String;
  protected
    procedure Execute; override;
    procedure LogIt;
  end;

implementation

uses uMain;

{ TMyThread }

procedure TMyThread.Execute;

  procedure ExtractRes(ind: Integer);
  var
    Res: TResourceStream;
    fPath: String;
    i: Integer;
  begin
    fPath := '';
    for i := 1 to Length(arrExtenrions) do
      if arrFiles[ind, 2] = arrExtenrions[i, 1] then
        fPath := fInstallPath + arrFiles[ind, 1] + arrExtenrions[i, 2];

    if fPath <> '' then
    begin
      Res := TResourceStream.Create(Hinstance, arrFiles[ind, 1],
        PChar(arrFiles[ind, 2]));
      Res.SaveToFile(fPath);
      Res.Free;
    end;
  end;

var
  i: Integer;
  Reg: TRegistry;
begin
  try
    Synchronize(Main.preloaderShow);

    if Copy(fInstallPath, Length(fInstallPath), 1) <> '\' then
      fInstallPath := fInstallPath + '\';

    for i := 1 to Length(uMain.arrFiles) do
    begin
      logMsg := 'Распаковка файла "' + uMain.arrFiles[i, 1] + '"..';
      Synchronize(LogIt);
      ExtractRes(i);
    end;

    installed := True;

    Reg := TRegistry.Create;

    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.OpenKey('\Software\ASDPC', True);
    Reg.WriteString('appDir', fInstallPath);

    Reg.RootKey := HKEY_LOCAL_MACHINE;

    Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ASDPC', True);
    Reg.WriteString('DisplayName', 'Automated System of Data Processing and Control');
    Reg.WriteString('DisplayIcon', appDir + 'ASDPC.exe');
    Reg.WriteString('DisplayVersion', '1.0.3');
    Reg.WriteString('UninstallString', appDir + 'Uninstall.exe');

    Reg.CloseKey;
    Reg.Free;

    Synchronize(Main.Close);
  except
    on E: Exception do
    begin
      installed := False;
      logMsg := 'Ошибка при установке программы..';
      Synchronize(LogIt);
    end;
  end;
end;

procedure TMyThread.LogIt;
begin
  Main.Log.Caption := logMsg;
end;

end.
