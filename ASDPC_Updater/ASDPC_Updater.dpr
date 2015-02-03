program ASDPC_Updater;

//{$APPTYPE CONSOLE}

{$R *.res}

{$R *.dres}

uses
  Winapi.Windows,
  ShellApi,
  SysUtils,
  System.Classes,
  Vcl.Dialogs,
  Vcl.Forms;

procedure ExtractRes(ResName, ResNewName, ResType: String);
var
  Res: TResourceStream;
begin
  Res := TResourceStream.Create(Hinstance, ResName, PChar(ResType));
  Res.SaveToFile(ResNewName);
  Res.Free;
end;

var
  i: Integer;
  sName, sOptions: String;

begin
  sName := GetEnvironmentVariable('TEMP') + '\asdpc_cache\ASDPC_Uploader.exe';
  if ParamCount > 0 then
    for i := 1 to ParamCount do
      sOptions := sOptions + ' ' + ParamStr(i);

  ExtractRes('Main', sName, 'APPL');

  ShellExecute(Application.Handle, nil, PChar(sName), PChar(sOptions), PChar(ExtractFilePath(sName)), SW_SHOWNORMAL);
end.
