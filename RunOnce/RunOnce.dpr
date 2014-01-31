program RunOnce;

uses
  Windows,
  SysUtils,
  Registry;

{$R *.res}

var
  Reg: TRegistry;
  appDir: String;

begin
  try
    if (ParamCount <> 1) or (ParamStr(1) <> '70D07BD1-8A42-43CE-986B-B57EA1F5CA77') then
      Exit;

    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.KeyExists('\Software\ASDPC') then
    begin
      Reg.OpenKey('\Software\ASDPC', False);
      if Reg.ValueExists('Login') then
        Reg.DeleteValue('Login');
      if Reg.ValueExists('Password') then
        Reg.DeleteValue('Password');
      if Reg.ValueExists('token') then
        Reg.DeleteValue('token');
      appDir := Reg.ReadString('appDir');

      Reg.RootKey := HKEY_LOCAL_MACHINE;

      Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ASDPC', True);
      Reg.WriteString('DisplayName', 'Automated System of Data Processing and Control');
      Reg.WriteString('DisplayIcon', appDir + 'ASDPC.exe');
      Reg.WriteString('DisplayVersion', '1.0.4');
      Reg.WriteString('UninstallString', appDir + 'Uninstall.exe');
    end;

    Reg.CloseKey;
    Reg.Free;
  except
    on E: Exception do
      Exit;
  end;
end.
