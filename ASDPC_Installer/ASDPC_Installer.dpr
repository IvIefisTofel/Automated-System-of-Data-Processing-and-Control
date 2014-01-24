program ASDPC_Installer;

{$R *.dres}

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {Main},
  Vcl.Themes,
  Vcl.Styles,
  uThread in 'uThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'ASDPC Installer';
  Application.CreateForm(TMain, Main);
  Application.Run;

end.
