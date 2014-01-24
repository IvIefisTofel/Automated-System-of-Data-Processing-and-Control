program ASDPC_Uploader;

{$R *.dres}

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {Main},
  Vcl.Themes,
  Vcl.Styles,
  uThread in 'uThread.pas',
  uCheckUpdate in 'uCheckUpdate.pas',
  uPasswords in '..\Libs\uPasswords.pas',
  uASDP_Update in '..\Libs\uASDP_Update.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Metropolis UI Blue');
  Application.Title := 'ASDPC Uploader';
  Application.CreateForm(TMain, Main);
  Application.Run;

end.
