unit uAuth;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ScktComp, ShellAPI, ExtCtrls, Registry, DBXJSON,
  uAuthValidate;

const
  HTML = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru" lang="ru" dir="ltr"><head><meta http-equiv="Content-Type" content="text/html;charset=utf-8"><title>ASDPC Status</title><link href="http://cs314717.vk.me/v314717880/6e7a/mcgnsEV8DUQ.jpg" rel="s'
    + 'hortcut icon" type="image/x-icon"><style type="text/css">.outer{width:800px;height:300px;border:4px #1e458a dotted;background-color:#e5edfa;padding:18px;color:#002157;font-size:inherit;font-weight:inherit;font-family:inherit;font-style:inherit;text-'
    + 'decoration:inherit;-webkit-border-radius:30px;-moz-border-radius:30px;border-radius:30px;-moz-box-shadow:0px 0px 10px 0px #333333;-webkit-box-shadow:0px 0px 10px 0px #333333;box-shadow:0px 0px 10px 0px #333333;margin:0 auto;}h1{margin:130 205;}.img{'
    + 'text-align:center;margin:20;}</style>{javascript}</head><body><div class="img"><img src="http://cs302808.vk.me/v302808880/6ed9/gJ-7rR4ttWo.jpg"></div><div class="outer"><h1>{text}</h1></div></body></html>;';

  HTML_Close = '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ru" lang="ru" dir="ltr"><head><script type="text/javascript">function func() {window.close();};document.ready = func();</script></head><body></body></html>';

  jsRedirect = '<script type="text/javascript">function func() {var asd = document.location.href;asd = asd.replace("#", "?");window.location.href = asd;};document.ready = func();</script>';
  jsOkay = '<script type="text/javascript">function func() {setTimeout(function(){open(location, "_self").close();}, 3000);};document.ready = func();</script>';

  oAuth = 'https://oauth.vk.com/authorize?client_id=4135152&scope=groups,offline&redirect_uri=http://localhost:9004&display=page&response_type=token';

type
  TUser = record
    access_token: String;
    userId: String;
    groupID: String;
  end;

  TAuth = class(TForm)
    btnLogin: TBitBtn;
    Remember_Me: TCheckBox;
    Server: TServerSocket;
    groupID: TLabeledEdit;
    procedure FormShow(Sender: TObject);
    procedure ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure AuthDone;
    procedure AuthError(ErrorMsg: String);
  public
    function FindMe: TUser;
    procedure FogetMe;
    procedure RememberMe(user: TUser);
    procedure ComponentsEnable(const Enable: Boolean);
  end;

var
  AuthValidate: TAuthValidate;
  VK_Valid: Boolean = False;

implementation

uses uMain;

{$R *.dfm}

{ TAuth }

procedure TAuth.AuthError(ErrorMsg: String);
begin
  VK_Valid := False;
  ShowMessage(ErrorMsg);
  ComponentsEnable(True);
  Show;
end;

procedure TAuth.AuthDone;
begin
  VK_Valid := True;
  Server.Active := False;
  if user.groupID <> gID then
  begin
    Data.ShowTimeTable.Visible := False;
    Data.bSeparator4.Visible := False;
    Data.ShowGDrive.Visible := False;
  end;
  NewsLoader.Resume;
  Updater.Resume;
  AuthValidate.Terminate;
  Destroy;
end;

procedure TAuth.ComponentsEnable(const Enable: Boolean);
begin
  Remember_Me.Enabled := Enable;
  btnLogin.Enabled := Enable;
  btnLogin.Enabled := Enable;
  Visible := Enable;
  Preloader.Visible := not Enable;
end;

function Encode(str: String): String;
var
  i: Integer;
begin
  for i := 1 to Length(str) do
    str[i] := Chr(Ord(str[i]) + 1);

  Result := str;
end;

function Decode(str: String): String;
var
  i: Integer;
begin
  for i := 1 to Length(str) do
    str[i] := Chr(Ord(str[i]) - 1);

  Result := str;
end;

function TAuth.FindMe: TUser;
var
  Reg: TRegistry;
begin
  Result.access_token := 'nil';
  Result.userId := 'nil';

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    if Reg.ReadString('') <> '' then
      Result.userId := Reg.ReadString('');
    if Reg.ReadString('token') <> '' then
      Result.access_token := Decode(Reg.ReadString('token'));
    if Reg.ReadString('gID') <> '' then
      Result.groupID := Reg.ReadString('gID');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

procedure TAuth.FogetMe;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    Reg.DeleteValue('');
    Reg.DeleteValue('gID');
    Reg.DeleteValue('token');
  end;

  Reg.CloseKey;
  Reg.Free;
end;

procedure TAuth.RememberMe(user: TUser);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  Reg.OpenKey('\Software\ASDPC',True);
  Reg.WriteString('', user.userId);
  if user.groupID = '' then
    user.groupID := gID;
  Reg.WriteString('gID', user.groupID);
  Reg.WriteString('token', Encode(user.access_token));

  Reg.CloseKey;
  Reg.Free;
end;

procedure TAuth.FormCreate(Sender: TObject);
begin
  user := FindMe;

  AuthValidate := TAuthValidate.Create(True);
  AuthValidate.Priority := tpNormal;
  AuthValidate.OnError := AuthError;
  AuthValidate.OnValid := AuthDone;
  AuthValidate.FreeOnTerminate := False;
  if not ((user.access_token= 'nil') and (user.userId = 'nil')) then
  begin
    AuthValidate.Resume;
  end else
    Auth.Show;
end;

procedure TAuth.FormShow(Sender: TObject);
begin
  ComponentsEnable(True);
  Server.Active := True;
  if user.groupID <> '' then
    groupID.Text := user.groupID
  else
    groupID.Text := gID;
end;

procedure TAuth.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  AuthValidate.Terminate;
  bClose := True;
  Main.Close;
end;

procedure TAuth.ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  ReceiveText, Response, Request, sError, GET: String;
begin
  ReceiveText := UTF8ToString(Socket.ReceiveText);

  if Pos('?', ReceiveText) <> 0 then
  begin
    GET := ReceiveText;
    Delete(GET, 1, Pos('?', ReceiveText));
    GET := Copy(GET, 1, Pos('HTTP/1.1', GET) - 2);

    if Pos('access_token', GET) <> 0 then
    begin
      user.access_token := GET;
      Delete(user.access_token, 1, Pos('access_token=', user.access_token) +
        Length('access_token=') - 1);
      user.access_token := Copy(user.access_token, 1, Pos('&', user.access_token) - 1);

      user.userId := GET;
      Delete(user.userId, 1, Pos('user_id=', user.userId) + Length('user_id=') - 1);

      Request := StringReplace(HTML, '{javascript}', jsOkay,
        [rfReplaceAll, rfIgnoreCase]);
      Request := StringReplace(Request, '{text}', 'Авторизация проканала))',
        [rfReplaceAll, rfIgnoreCase]);

      Socket.SendText(UTF8Encode(Request));
      Auth.Server.Active := False;
      Auth.Server.Active := True;

      Sleep(3000);
      SetForeGroundWindow(Auth.Handle);

      AuthValidate.Resume;
    end else
    begin
      if Pos('error_description', GET) <> 0 then
        sError := GET;
      Delete(sError, 1, Pos('error_description=', sError) +
        Length('error_description=') - 1);
      sError := StringReplace(sError, '%20', ' ', [rfReplaceAll, rfIgnoreCase]);

      Request := StringReplace(HTML, '{javascript}', jsOkay,
        [rfReplaceAll, rfIgnoreCase]);
      Request := StringReplace(Request, '{text}', sError,
        [rfReplaceAll, rfIgnoreCase]);

      Socket.SendText(UTF8Encode(Request));
      Auth.Server.Active := False;
      Auth.Server.Active := True;

      Sleep(3000);
      SetForeGroundWindow(Auth.Handle);

      AuthError('Ошибка авторизации.'#13#10'Причина: ' + sError);
    end;
  end else
  begin
    Request := StringReplace(HTML, '{javascript}', jsRedirect,
      [rfReplaceAll, rfIgnoreCase]);
    Request := StringReplace(Request, '{text}', 'Еще один шажок.........',
      [rfReplaceAll, rfIgnoreCase]);

    Socket.SendText(UTF8Encode(Request));
    Auth.Server.Active := False;
    Auth.Server.Active := True;
  end;
end;

procedure TAuth.btnLoginClick(Sender: TObject);
begin
  ComponentsEnable(False);
  user.groupID := groupID.Text;
  if (user.access_token = 'nil') or (user.userId = 'nil') or (user.groupID = '') then
    ShellExecute(Handle, 'open', oAuth, nil, nil, 0)
  else
    AuthValidate.Resume;
end;

end.
