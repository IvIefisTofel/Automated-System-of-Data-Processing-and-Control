program Uninstall;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {Main},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
