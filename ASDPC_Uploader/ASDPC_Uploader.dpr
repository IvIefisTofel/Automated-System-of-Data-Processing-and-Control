program ASDPC_Uploader;

{$R *.dres}

uses
  SysUtils,
  Windows,
  Messages,
  Forms,
  Themes,
  Styles,
  uMain in 'uMain.pas' {Main},
  uDataModule in 'uDataModule.pas' {Data: TDataModule},
  uConnectServer in 'uConnectServer.pas',
  uUpdate in 'uUpdate.pas',
  uHelper in '..\Libs\uHelper.pas',
  uPasswords in '..\Libs\uPasswords.pas';

{$R *.res}

function AppExist: boolean;
var
  wnd: HWND;
  cd: TCopyDataStruct;
  s: String;
begin
  wnd := FindWindow('TSimpleDataBase', nil);
  if wnd <> 0 then
  begin
    result := true;
    if ParamCount = 0 then
      Exit;
    s := ParamStr(1);
    cd.dwData := $BEBE;
    cd.cbData := (1+Length(s))*SizeOf(String);
    cd.lpData := PChar(s);
    SendMessage(wnd, WM_COPYDATA, 0, Integer(@cd));
  end
  else
    result := false;
end;

begin
  if AppExist then
    Exit;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'ASDPC Uploader';
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TData, Data);
  Application.Run;
end.
