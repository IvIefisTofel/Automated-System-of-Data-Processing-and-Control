unit uAuthValidate;

interface

uses
  Windows, SysUtils, Classes, ScktCOMP , DBXJSON, uGoogle, uHelper, Dialogs,
  IdTCPClient;

type
  FError = procedure(ErrorMsg: String) of Object;
  FValid = procedure of Object;

  TAuthValidate = class(TThread)
  private
    FErrMsg: String;
    FUserInfo: String;
    FAvatarUrl: String;
  public
    OnError: FError;
    OnValid: FValid;
  protected
    procedure Execute; override;
    procedure LoadUserInfo;
    procedure LogToRegistry;
    procedure DoOnError;
  end;

procedure CheckInternet;

var
  IsInternet: Boolean;

implementation

uses uMain, uAuth;

procedure CheckInternet;
var
  TCP: TIdTCPClient;
begin
  try
    TCP := TIdTCPClient.Create(nil);
    TCP.Host := 'google.com';
    TCP.Port := 80;
    TCP.ReadTimeout := 2000;
    try
      TCP.Connect;
      IsInternet := TCP.Connected;
    except
      IsInternet := False;
    end;
  finally
    TCP.Free;
  end;
end;

{ TAuthValidate }

procedure TAuthValidate.LoadUserInfo;
begin
  Main.UserInfo.Caption := FUserInfo;
  Data.downloadImage(FAvatarUrl, Main.Avatar);
end;

procedure TAuthValidate.LogToRegistry;
begin
  if Auth.Remember_Me.Checked then
    Auth.RememberMe(user)
  else
    Auth.FogetMe;
end;

procedure TAuthValidate.DoOnError;
begin
  if Assigned(OnError) then
    OnError(FErrMsg);
end;

procedure TAuthValidate.Execute;
var
  jObj: TJSONObject;
  Response: TStringStream;
  ResponseString: String;
begin
  while not Terminated do
  begin
    try
      CheckInternet;
      if IsInternet then
      begin
        Response := TStringStream.Create;
        Google.Get('https://api.vk.com/method/groups.isMember?gid=' + user.groupID + '&access_token='+ user.access_token, Response, True);
        if Pos('error', UTF8ToString(Response.DataString)) = 0 then
        begin
          jObj := TJSONObject.ParseJSONValue(Response.DataString) as TJSONObject;
          if Assigned(jObj) then
            if StrToBool((jObj.Get(0).JsonValue as TJSONString).Value) then
            begin
              Response.Clear;
              Google.Get('https://api.vk.com/method/users.get?uids=' + user.userId + '&fields=first_name,last_name,photo_medium&access_token='+ user.access_token, Response, True);
              if Pos('error', UTF8ToString(Response.DataString)) = 0 then
              begin
                jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
                if Assigned(jObj) then
                begin
                  jObj := (jObj.Get(0).JsonValue as TJSONArray).Get(0) as TJSONObject;
                  FUserInfo := 'Вы авторизованы как'#13#10
                    + (jObj.Get('first_name').JsonValue as TJSONString).Value + ' '
                    + (jObj.Get('last_name').JsonValue as TJSONString).Value;
                  FAvatarUrl := StringReplace((jObj.Get('photo_medium').JsonValue as TJSONString).Value,
                    '\', '', [rfReplaceAll, rfIgnoreCase]);
                  Synchronize(LoadUserInfo);
                  Synchronize(LogToRegistry);
                  if Assigned(OnValid) then
                    Synchronize(OnValid);
                end;
              end else
              begin
                user.access_token := EmptyStr;
                user.userId := EmptyStr;
                user.groupID := EmptyStr;
                FErrMsg := 'Ошибка авторизации';
                Synchronize(DoOnError);
              end;
            end else
            begin
              FErrMsg := 'Вы не состоите в группе "vk.com/club' + user.groupID + '"';
              Synchronize(DoOnError);
            end;
        end else
        begin
          user.access_token := EmptyStr;
          user.userId := EmptyStr;
          user.groupID := EmptyStr;
          FErrMsg := 'Ошибка авторизации';
          Synchronize(DoOnError);
        end;
        Response.Free;
      end else
      begin
        FErrMsg := 'Отсутствует интернет соединение!';
        Synchronize(DoOnError);
      end;
    except
      on E:Exception do
      begin
        Response.Free;
        FErrMsg := 'Ошибка получения данных';
        Synchronize(DoOnError);
        Terminate;
      end;
    end;
    Suspend;
  end;
end;

end.
