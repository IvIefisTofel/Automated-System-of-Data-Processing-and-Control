unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Registry, StdCtrls, Buttons, IniFiles, ShellApi, ShlObj;

type
  TMain = class(TForm)
    DelBtn: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  deleted: Boolean = False;
  appDir: String = '';

implementation

{$R *.dfm}

function GetTempDir: String;
var
  path: array[0..MAX_PATH] of WideChar;
begin
  GetTempPath(MAX_PATH, path);
  Result := path;
end;

function GetDeskTopDir: string;
var
  SpecialDir: PItemIdList;
begin
  SetLength(result, MAX_PATH);
  SHGetSpecialFolderLocation(Application.Handle, CSIDL_DESKTOP, SpecialDir);
  SHGetPathFromIDList(SpecialDir, PChar(Result));
  SetLength(Result, lStrLen(PChar(Result)));
  Result := Result + '\';
end;

procedure RemoveAutorun;
var
  RootKey: HKEY;
  Key: HKEY;
  Name: String;
  CommandLine: String;
begin
  RootKey := HKEY_CURRENT_USER;
  Name := 'ASDPC';
  CommandLine := Format('"%s"', [ParamStr(0)]);

  SetLastError(RegOpenKeyEx(RootKey, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 0, KEY_WRITE, Key));
  if GetLastError <> ERROR_SUCCESS then
    RaiseLastOSError;

  SetLastError(RegDeleteValue(Key, PChar(Name)));

  if (GetLastError <> ERROR_SUCCESS) and
     (GetLastError <> ERROR_FILE_NOT_FOUND) then
    RaiseLastOSError;
end;

procedure self_deletion(const stop: Boolean = False);
const
  batName = 'del.bat';
var
  batFile: TextFile;
begin
  AssignFile(batFile, GetTempDir + batName);
  Rewrite(batFile);
  Writeln(batFile, '@echo off');
  Writeln(batFile, ':try');
  Writeln(batFile, 'del /q "' + appDir + ExtractFileName(ParamStr(0)) + '"');
  Writeln(batFile, 'if exist "' + appDir + ExtractFileName(ParamStr(0)) + '" goto try');
  Writeln(batFile, 'rd "' + appDir + '"');
  Writeln(batFile, 'del /q "%TEMP%\' + batName + '"');
  CloseFile(batFile);
  ShellExecute(Application.Handle, 'open', PChar(GetTempDir + batName), nil, nil, SW_HIDE);
  if stop then
   halt;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
begin
  Main.Close;

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    appDir := Reg.ReadString('appDir');
  end;

  Reg.CloseKey;
  Reg.Free;

  if appDir = '' then
    DelBtn.Enabled := False;
end;

procedure TMain.DelBtnClick(Sender: TObject);
var
  Ini: TIniFile;
  appList: TStringList;
  i: Integer;
  Reg: TRegistry;
begin
  DelBtn.Enabled := False;

  Ini := TIniFile.Create(appDir + 'update.ini');
  appList := TStringList.Create;

  Ini.ReadSection('ASDPC', appList);

  for i := 0 to appList.Count - 1 do
  begin
    appList[i] := Ini.ReadString('ASDPC', appList[i], '');
    if FileExists(appDir + appList[i]) and (appList[i] <> ExtractFileName(ParamStr(0))) then
      if not DeleteFile(appDir + appList[i]) then
      begin
        ShellExecute(Handle, nil, PChar(appDir + appList[i]), 'exit', PChar(appDir), SW_NORMAL);
        Sleep(3000);
        DeleteFile(appDir + appList[i]);
      end;
  end;
  Ini.Free;

  DeleteFile(appDir + 'update.ini');
  DeleteFile(appDir + 'RunOnce.exe');
  DeleteFile(appDir + 'cache\timetable.csv');
  DeleteFile(appDir + 'cache\watsnew.txt');
  RemoveDir(appDir + 'cache');
  DeleteFile(GetDeskTopDir + 'ASDPC.lnk');

  RemoveAutorun;

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
    Reg.DeleteKey('\Software\ASDPC');

  Reg.RootKey := HKEY_LOCAL_MACHINE;

  if Reg.KeyExists('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ASDPC') then
    Reg.DeleteKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ASDPC');

  Reg.CloseKey;
  Reg.Free;

  self_deletion;
  Main.Close;
end;

end.
