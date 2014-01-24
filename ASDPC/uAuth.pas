unit uAuth;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, DBXJSON,
  System.Win.ScktComp, IdCoder, IdCoder3to4, IdCoder00E, IdCoderXXE,
  ShellAPI, IdBaseComponent, uMain, uData, Registry, lib, ssl_openssl, httpsend;

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
  TAuth = class(TForm)
    btnLogin: TBitBtn;
    Remember_Me: TCheckBox;
    Server: TServerSocket;
    procedure FormShow(Sender: TObject);
    procedure ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLoginClick(Sender: TObject);
  public
    function VK_Valid: Boolean;
    function FindMe: TUser;
    procedure FogetMe;
    procedure RememberMe(user: TUser);
  end;

var
  Auth: TAuth;
  authResult: Boolean = False;

implementation

{$R *.dfm}

{ TAuth }

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

function TAuth.VK_Valid: Boolean;
var
  jObj: TJSONObject;
  Response: String;
begin
  Result := False;

  Response := UTF8ToString(send('GET', 'https://api.vk.com/method/groups.isMember?gid=' + gId + '&access_token='+ user.access_token));
  if Pos('error', Response) = 0 then
  begin
    jObj := TJSONObject.ParseJSONValue(Response) as TJSONObject;
    if Assigned(jObj) then
      if StrToBool((jObj.Get(0).JsonValue as TJSONString).Value) then
      begin
        Result := True;
        Response := UTF8ToString(send('GET', 'https://api.vk.com/method/users.get?uids=' + user.userId + '&fields=first_name,last_name,photo_medium&access_token='+ user.access_token));
        if Pos('error', Response) = 0 then
        begin
          jObj := TJSONObject.ParseJSONValue(Response) as TJSONObject;
          if Assigned(jObj) then
          begin
            jObj := (jObj.Get(0).JsonValue as TJSONArray).Get(0) as TJSONObject;
            Main.UserInfo.Caption := 'Вы авторизованы как'#13#10
              + (jObj.Get('first_name').JsonValue as TJSONString).Value + ' '
              + (jObj.Get('last_name').JsonValue as TJSONString).Value;
            Data.downloadImage(StringReplace((jObj.Get('photo_medium').JsonValue as TJSONString).Value, '\', '', [rfReplaceAll, rfIgnoreCase]), Main.Avatar);
          end;
        end;
        if Remember_Me.Checked then
          RememberMe(user)
        else
          FogetMe;
      end else
      begin
        ShowMessage('Вы не являетесь студентом группы Б01-782-1.');
        Remember_Me.Enabled := True;
        btnLogin.Enabled := True;
      end;
  end;
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
      Result.access_token := Reg.ReadString('token');
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

  Reg.DeleteKey('\Software\ASDPC');

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
  Reg.WriteString('token', user.access_token);

  Reg.CloseKey;
  Reg.Free;
end;

procedure TAuth.FormShow(Sender: TObject);
begin
  Server.Active := True;
end;

procedure TAuth.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Server.Active := False;
  if authResult then
  begin
    Data.Timer.Enabled := True;
    Data.CheckUpdate.Enabled := True;
    Data.formatNews;
  end else
  begin
    bClose := True;
    Main.Close;
  end;
end;

procedure TAuth.ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  Response, sError, ReceiveText, GET, request: String;
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

      request := StringReplace(HTML, '{javascript}', jsOkay,
        [rfReplaceAll, rfIgnoreCase]);
      request := StringReplace(request, '{text}', 'Авторизация проканала))',
        [rfReplaceAll, rfIgnoreCase]);

      Socket.SendText(UTF8Encode(request));
      Server.Active := False;

      Sleep(3000);
      SetForeGroundWindow(Auth.Handle);
      if VK_Valid then
      begin
        Data.Tray.Visible := True;
        Data.AutoRun := true;
        authResult := True;
        Auth.Close;
        Exit;
      end;
    end
    else
    begin
      if Pos('error_description', GET) <> 0 then
        sError := GET;
      Delete(sError, 1, Pos('error_description=', sError) +
        Length('error_description=') - 1);
      sError := StringReplace(sError, '%20', ' ', [rfReplaceAll, rfIgnoreCase]);

      request := StringReplace(HTML, '{javascript}', jsOkay,
        [rfReplaceAll, rfIgnoreCase]);
      request := StringReplace(request, '{text}', sError,
        [rfReplaceAll, rfIgnoreCase]);

      Socket.SendText(UTF8Encode(request));
      Server.Active := False;

      Sleep(3000);
      SetForeGroundWindow(Auth.Handle);
      ShowMessage('Ошибка авторизации.'#13#10'Причина: ' + sError);
      Remember_Me.Enabled := True;
      btnLogin.Enabled := True;
    end;
  end
  else
  begin
    request := StringReplace(HTML, '{javascript}', jsRedirect,
      [rfReplaceAll, rfIgnoreCase]);
    request := StringReplace(request, '{text}', 'Еще один шажок.........',
      [rfReplaceAll, rfIgnoreCase]);

    Socket.SendText(UTF8Encode(request));
    Server.Active := False;
    Server.Active := True;
  end;
end;

procedure TAuth.btnLoginClick(Sender: TObject);
begin
  Remember_Me.Enabled := False;
  btnLogin.Enabled := False;
  ShellExecute(Handle, 'open', oAuth, nil, nil, 0);
end;

end.
