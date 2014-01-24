unit AutorunReg;

interface

type
  TAutorunAction = (aaAdd, aaRemove);

// Реестр
procedure AutorunAddReg(const AGlobal: Boolean = False; const AParams: String = '');
procedure AutorunRemoveReg(const AGlobal: Boolean = False);
function  AutorunCheckReg(const AGlobal: Boolean = False; const AName: String = ''): Boolean;

// Папка "Автозагрузка"
procedure AutorunAddLnk(const AGlobal: Boolean = False; const AParams: String = '');
procedure AutorunRemoveLnk(const AGlobal: Boolean = False);
function  AutorunCheckLnk(const AGlobal: Boolean = False; const AName: String = ''): Boolean;

// Низкий уровень
procedure AutorunControlReg(const AAction: TAutorunAction; const AGlobal: Boolean; const AName: String = ''; const ACommandLine: String = '');
procedure AutorunControlLnk(const AAction: TAutorunAction; const AGlobal: Boolean; const AName: String = ''; const ACommandLine: String = '');

implementation

uses
  Windows,
  SysUtils,
  ShlObj,
  ComObj,
  ActiveX;

const
  AutoRunRegistryKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; // Do Not Localize
  LnkFileExtension   = '.lnk'; // Do Not Localize

procedure CheckParams(var AName, ACommandLine: String);
begin
  if AName = '' then
    AName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  if AName = '' then // маловероятно, но стоит проверить
    AName := ExtractFileName(ParamStr(0));
  if ACommandLine = '' then
    ACommandLine := Format('"%s"', [ParamStr(0)]);
end;

procedure AutorunControlReg(const AAction: TAutorunAction; const AGlobal: Boolean; const AName, ACommandLine: String);
var
  RootKey: HKEY;
  Key: HKEY;
  Name: String;
  CommandLine: String;
begin
  // Проверка параметров:
  if AGlobal then
    RootKey := HKEY_LOCAL_MACHINE
  else
    RootKey := HKEY_CURRENT_USER;
  Name := AName;
  CommandLine := ACommandLine;
  CheckParams(Name, CommandLine);

  // Открыли ключ
  SetLastError(RegOpenKeyEx(RootKey, AutoRunRegistryKey, 0, KEY_WRITE, Key));
  if GetLastError <> ERROR_SUCCESS then
    RaiseLastOSError;

  // Добавляем или удаляем
  case AAction of
    aaAdd:
      SetLastError(RegSetValueEx(Key, PChar(Name), 0, REG_SZ, PChar(CommandLine), (Length(CommandLine) + 1) * SizeOf(Char)));
    aaRemove:
      SetLastError(RegDeleteValue(Key, PChar(Name)));
  else
    Assert(False);
  end;
  // относится к RegSetValue/RegDeleteKey
  if (GetLastError <> ERROR_SUCCESS) and
     (GetLastError <> ERROR_FILE_NOT_FOUND) then // RegDeleteKey для несуществующего ключа
    RaiseLastOSError;
end;

function  AutorunCheckReg(const AGlobal: Boolean = False; const AName: String = ''): Boolean;
var
  RootKey: HKEY;
  Key: HKEY;
  Name: String;
  Dummy: String;
  DataType: DWORD;
begin
  // Проверка параметров:
  if AGlobal then
    RootKey := HKEY_LOCAL_MACHINE
  else
    RootKey := HKEY_CURRENT_USER;
  Name := AName;
  Dummy := 'x';
  CheckParams(Name, Dummy);

  // Открыли ключ
  SetLastError(RegOpenKeyEx(RootKey, AutoRunRegistryKey, 0, KEY_READ, Key));
  if GetLastError <> ERROR_SUCCESS then
    RaiseLastOSError;

  // Есть ли наше значение?
  Result := False;
  SetLastError(RegQueryValueEx(Key, PChar(Name), nil, @DataType, nil, nil));
  if GetLastError = ERROR_SUCCESS then
    Result := True
  else
  if GetLastError <> ERROR_FILE_NOT_FOUND then
    RaiseLastOSError;
end;

// Простые переходники
procedure AutorunAddReg(const AGlobal: Boolean; const AParams: String);
begin
  AutorunControlReg(aaAdd, AGlobal, '', Trim(Format('"%s" %s', [ParamStr(0), AParams])));
end;

procedure AutorunRemoveReg(const AGlobal: Boolean);
begin
  AutorunControlReg(aaRemove, AGlobal);
end;

procedure GetLinkInfo(const AGlobal: Boolean; const AName: String; const ACommandLine: String; out ALnkFileName, AProgramFile, AParams: String);
var
  Folder: Integer;
  Path: String;
  Ind: Integer;
begin
  if AGlobal then
    Folder := CSIDL_COMMON_STARTUP
  else
    Folder := CSIDL_STARTUP;
  SetLength(Path, MAX_PATH + 1);
  Win32Check(SHGetSpecialFolderPath(0, PChar(Path), Folder, True));
  SetLength(Path, StrLen(PChar(Path)));
  Path := IncludeTrailingPathDelimiter(Path);
  ALnkFileName := Path + AName + LnkFileExtension;

  AProgramFile := Trim(ACommandLine);
  Ind := Pos(' ', AProgramFile);
  // Без аргументов
  // "C:\Programs\MyFile.exe"
  // или
  // C:\Programs\MyFile.exe
  if Ind <= 0 then
  begin
    AParams := '';
    if AProgramFile[1] = '"' then
      AProgramFile := Trim(Copy(AProgramFile, 2, Length(AProgramFile) - 2));
  end
  else
  begin
    // Аргументы есть, кавычки тоже
    // "C:\Program Files\MyFile.exe" /Params "/Params 2"
    if AProgramFile[1] = '"' then
    begin
      AProgramFile := Trim(Copy(AProgramFile, 2, MaxInt));
      Ind := Pos('"', AProgramFile);
    end;

    AParams := Trim(Copy(AProgramFile, Ind + 1, MaxInt));
    AProgramFile := Copy(AProgramFile, 1, Ind - 1);
  end;
end;

function ExtractFileDescription(const AFileName: String): String;
begin
  // Пока так, а вообще-то тут можно вернуть описание файла из его версионной информации
  Result := AFileName;
end;

procedure AutorunControlLnk(const AAction: TAutorunAction; const AGlobal: Boolean; const AName, ACommandLine: String);

  procedure CreateLink(const ALnkPath, AFile, AParam, ADescription: String);
  var
    IObject: IUnknown;
    SLink: IShellLink;
    PFile: IPersistFile;
  begin
    IObject := CreateComObject(CLSID_ShellLink);
    SLink := IObject as IShellLink;
    PFile := IObject as IPersistFile;

    SLink.SetPath(PChar(AFile));
    SLink.SetArguments(PChar(AParam));
    SLink.SetDescription(PChar(ADescription));
    PFile.Save(PWChar(WideString(ALnkPath)), False);
  end;

var
  Name: String;
  CommandLine: String;
  LnkFileName: String;
  ProgramFile: String;
  Params: String;
  Description: String;
begin
  // Проверка параметров:
  Name := AName;
  CommandLine := ACommandLine;
  CheckParams(Name, CommandLine);
  GetLinkInfo(AGlobal, Name, CommandLine, LnkFileName, ProgramFile, Params);

  // Создание или удаление ярлыка:
  case AAction of
    aaAdd:
    begin
      Description := ExtractFileDescription(ProgramFile);
      CreateLink(LnkFileName, ProgramFile, Params, Description);
    end;
    aaRemove:
    begin
      if (not DeleteFile(LnkFileName)) and
         (GetLastError <> ERROR_FILE_NOT_FOUND) then
        RaiseLastOSError;
    end;
  else
    Assert(False);
  end;
end;

function  AutorunCheckLnk(const AGlobal: Boolean; const AName: String): Boolean;
var
  Name: String;
  CommandLine: String;
  LnkFileName: String;
  ProgramFile: String;
  Params: String;
begin
  // Проверка параметров:
  Name := AName;
  CommandLine := '';
  CheckParams(Name, CommandLine);
  GetLinkInfo(AGlobal, Name, CommandLine, LnkFileName, ProgramFile, Params);

  // Есть ли наш ярлык?
  Result := FileExists(LnkFileName);
end;

// Простые переходники
procedure AutorunAddLnk(const AGlobal: Boolean; const AParams: String);
begin
  AutorunControlLnk(aaAdd, AGlobal, '', Trim(Format('"%s" %s', [ParamStr(0), AParams])));
end;

procedure AutorunRemoveLnk(const AGlobal: Boolean);
begin
  AutorunControlLnk(aaRemove, AGlobal);
end;

end.
