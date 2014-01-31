program ASDPC_Uploader;

{$R *.dres}

uses
  SysUtils,
  Windows,
  Messages,
  Forms,
  Themes,
  Styles,
  uMain in 'uMain.pas' {ASDPCUploader},
  uConnectServer in 'uConnectServer.pas',
  uUpdate in 'uUpdate.pas',
  uHelper in '..\Libs\uHelper.pas',
  uPasswords in '..\Libs\uPasswords.pas',
  uGoogle in '..\Libs\uGoogle.pas';

{$R *.res}

function AppExist: boolean;
var
  wnd: HWND;
  cd: TCopyDataStruct;
  Params: String;
begin
  wnd := FindWindow('TASDPCUploader', nil);
  if wnd <> 0 then
  begin
    Result := True;
    if ParamCount = 0 then
      Exit;
    Params := ParamStr(1);
    cd.dwData := $BEBE;
    cd.cbData := (1 + Length(Params)) * SizeOf(String);
    cd.lpData := PChar(Params);
    SendMessage(wnd, WM_COPYDATA, 0, Integer(@cd));
  end else
    Result := False;
end;

begin
  if AppExist then
    Exit;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'ASDPC Uploader';
  Application.CreateForm(TASDPCUploader, ASDPCUploader);
  Application.Run;
end.
