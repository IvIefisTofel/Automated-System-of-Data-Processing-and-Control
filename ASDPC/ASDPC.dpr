program ASDPC;

uses
  Forms,
  Windows,
  Themes,
  Styles,
  uMain in 'uMain.pas' {Main},
  uAuth in 'uAuth.pas' {Auth},
  uDataModule in 'uDataModule.pas' {Data: TDataModule},
  uCheckUpdate in 'uCheckUpdate.pas',
  uHelper in '..\Libs\uHelper.pas',
  uPasswords in '..\Libs\uPasswords.pas';

{$R *.res}

begin
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'Automated System of Data Processing and Control';

  Application.Initialize;
  Application.ShowMainForm := False;
  Application.CreateForm(TData, Data);
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TAuth, Auth);
  Application.Run;
end.
