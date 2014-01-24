unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ComCtrls,
  Vcl.ExtCtrls, Registry, ShellApi, uThread, GifImg, PNGImage, FileCtrl;

type
  TMain = class(TForm)
    Preloader: TImage;
    InstallBtn: TBitBtn;
    Icon: TImage;
    fPath: TEdit;
    fPathLabel: TLabel;
    AutoStart: TCheckBox;
    fPathBtn: TBitBtn;
    Log: TLabel;
    procedure InstallBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure fPathBtnClick(Sender: TObject);
    procedure fPathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure preloaderShow;
  end;

const
  arrFiles: array[1..4, 1..2] of String = (
    ('ASDPC_Updater', 'APPL'),
    ('libeay32', 'LIB'),
    ('msvcr71', 'LIB'),
    ('ssleay32', 'LIB')
  );
  arrExtenrions: array[1..2, 1..2] of String = (
    ('APPL', '.exe'),
    ('LIB', '.dll')
  );

var
  Main: TMain;
  installed: Boolean = False;
  appDir: String = '';

implementation

{$R *.dfm}

function GetProgramFilesDir: string;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion', False);
    Result := reg.ReadString('ProgramFilesDir');
  finally
    reg.Free;
  end;
end;

{ TMain }

procedure TMain.preloaderShow;
begin
  fPath.Enabled := False;
  fPathBtn.Enabled := False;
  AutoStart.Enabled := False;
  InstallBtn.Enabled := False;
  Preloader.Show;
  Icon.Hide;
end;

procedure TMain.fPathBtnClick(Sender: TObject);
var
  chosenDirectory: String;
begin
  if SelectDirectory('Выберите каталог', '', chosenDirectory) then
    if Length(chosenDirectory) = 3 then
      fPath.Text := chosenDirectory + 'ASDPC\'
    else
      fPath.Text := chosenDirectory + '\ASDPC\';
end;

procedure TMain.fPathKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  fPathBtn.Click;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    appDir := Reg.ReadString('appDir');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

procedure TMain.FormShow(Sender: TObject);
var
  Res: TResourceStream;
  Gif: TGIFImage;
  My: TMyThread;
begin
  Res := TResourceStream.Create(Hinstance, 'Preloader', 'IMAGE');
  Gif := TGIFImage.Create;
  Gif.LoadFromStream(Res);
  Res.Free;

  fPath.Text := GetProgramFilesDir + '\ASDPC\';

  Gif.Animate := True;
  Main.Preloader.Picture.Assign(Gif);
  Gif.Free;

  if (appDir <> '') and FileExists(appDir + 'ASDPC.exe') then
  begin
    fPath.Text := appDir;
    fPath.Enabled := False;
    fPathBtn.Enabled := False;
    AutoStart.Enabled := False;
    Log.Caption := 'Программа уже установленна';
    InstallBtn.Caption := 'Выход';
  end;
end;

procedure TMain.InstallBtnClick(Sender: TObject);
var
  My: TMyThread;
begin
  if InstallBtn.Caption = 'Выход' then
    Main.Close;
  if fPath.Text <> '' then
  begin
    if fPath.Text[Length(fPath.Text)] <> '\' then
      fPath.Text := fPath.Text + '\';
    if not DirectoryExists(fPath.Text) then
      CreateDir(fPath.Text);

    My := TMyThread.Create(True);
    My.Priority := tpNormal;
    My.fInstallPath := fPath.Text;
    My.FreeOnTerminate := True;
    My.Resume;
  end;
end;

procedure TMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  sPath, sOptions: String;
begin
  if installed then
  begin
    sPath := fPath.Text + arrFiles[1, 1] + arrExtenrions[1, 2];
    if AutoStart.Checked and FileExists(sPath) then
      sOptions := 'updateAndRestart'
    else
      sOptions := 'update';
    ShellExecute(Handle, nil, PChar(sPath), PChar(sOptions), nil, SW_SHOWNORMAL);
  end;
end;

end.
