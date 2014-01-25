program ASDPC_Installer;

{$R *.dres}

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles
  uMain in 'uMain.pas' {Main},,
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
