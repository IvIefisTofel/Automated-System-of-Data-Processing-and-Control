program ASDPC;

{$R *.dres}

uses
  SysUtils,
  Windows,
  Messages,
  Forms,
  Themes,
  Styles,
  uDataModule in 'uDataModule.pas' {Data: TDataModule},
  uMain in 'uMain.pas' {Main},
  uPreloader in 'uPreloader.pas' {Preloader},
  uDrive in 'uDrive.pas' {Drive},
  uTimeTable in 'uTimeTable.pas' {TimeTable},
  uWatsNew in 'uWatsNew.pas' {WatsNew},
  uAuth in 'uAuth.pas' {Auth},
  uAuthValidate in 'uAuthValidate.pas',
  uUpdater in 'uUpdater.pas',
  uNewsLoader in 'uNewsLoader.pas',
  uGoogle in '..\Libs\uGoogle.pas',
  uHelper in '..\Libs\uHelper.pas',
  uPasswords in '..\Libs\uPasswords.pas';

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

  Application.Initialize;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'Automated System of Data Processing and Control';
  Application.ShowMainForm := False;
  Application.CreateForm(TData, Data);
  Application.CreateForm(TASDPC_Main, Main);
  Application.CreateForm(TPreloader, Preloader);
  Application.CreateForm(TDrive, Drive);
  Application.CreateForm(TTimeTable, TimeTable);
  Application.CreateForm(TWatsNew, WatsNew);
  Application.CreateForm(TAuth, Auth);
  Application.Run;
end.
