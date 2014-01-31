program ASDPC;



uses
  SysUtils,
  Windows,
  Messages,
  Forms,
  Themes,
  Styles,
  uMain in 'uMain.pas' {ASDPC_Main},
  uAuth in 'uAuth.pas' {Auth},
  uDataModule in 'uDataModule.pas' {Data: TDataModule},
  uCheckUpdate in 'uCheckUpdate.pas',
  uHelper in '..\Libs\uHelper.pas',
  uPasswords in '..\Libs\uPasswords.pas',
  uWatsNew in 'uWatsNew.pas' {WatsNew},
  uTimeTable in 'uTimeTable.pas' {TimeTable},
  uGoogle in '..\Libs\uGoogle.pas',
  uDrive in 'uDrive.pas' {Drive},
  uDriveViewer in 'uDriveViewer.pas';

{$R *.res}

function AppExist: boolean;
var
  wnd: HWND;
  cd: TCopyDataStruct;
  Params: String;
begin
  wnd := FindWindow('TASDPC_Main', nil);
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
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'Automated System of Data Processing and Control';

  Application.Initialize;
  Application.ShowMainForm := False;
  Application.CreateForm(TData, Data);
  Application.CreateForm(TASDPC_Main, ASDPC_Main);
  Application.CreateForm(TAuth, Auth);
  Application.CreateForm(TWatsNew, WatsNew);
  Application.CreateForm(TTimeTable, TimeTable);
  Application.CreateForm(TDrive, Drive);
  Application.Run;
end.
