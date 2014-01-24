program ASDPC;

uses
  Forms,
  Windows,
  uAuth in 'uAuth.pas' {Auth},
  Vcl.Themes,
  Vcl.Styles,
  uMain in 'uMain.pas' {Main},
  uData in 'uData.pas' {Data: TDataModule},
  uCheckUpdate in 'uCheckUpdate.pas',
  uASDP_Update in '..\Libs\uASDP_Update.pas',
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
