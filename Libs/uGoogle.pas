unit uGoogle;

interface

uses
  Forms, Classes, SysUtils, CommCtrl, ComCtrls, StdCtrls, DBXJSON, dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  Controls, uPasswords, Graphics, AdvSmoothProgressBar;

const
  {$REGION 'Эти 3 параметра загружаются из модуля uPasswords'}
  UClientId = PClientId;
  UClientSecret = PClientSecret;
  URefreshToken = PRefreshToken;
  {$ENDREGION}

  NullDate = -7274;
  cTokenURL = 'https://accounts.google.com/o/oauth2/token';

type
  TOnGet = procedure(Stream: TStream) of object;
  TAfterDestroy = procedure(Top, Left, Height, Width: Integer) of object;

  TPBarParams = record
    Top: Integer;
    Left: Integer;
    Width: Integer;
    Height: Integer;
    Anchors: TAnchors;
    AOwner: TComponent;
    Parent: TWinControl;
    BeforeCreate: TNotifyEvent;
    AfterDestroy: TAfterDestroy;
    Size: Int64;
  end;

  TGoogle = class
  private
  type
    TGet = class(TThread)
    private
      HTTP: TIdHTTP;
      SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
      pBar: TAdvSmoothProgressBar;
      pBarCreated: Boolean;
      pBarParams: TPBarParams;
      pBarMax: Int64;
      pBarPos: Int64;
      Stream: TStream;
      FOnGet: TOnGet;
    public
      TokenType: String;
      AccessToken: String;
      Url: String;
      fName: String;
      CreatePBar: Boolean;
      property OnGet: TOnGet read FOnGet write FOnGet;
    protected
      procedure Execute; override;
      procedure DoOnGet;
      procedure Work(ASender: TObject; AWorkMode: TWorkMode;
        AWorkCount: Int64);
      procedure WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
      procedure pBarWork;
      procedure pBarWorkEnd;
      procedure pBarCreate;
      procedure pBarDestroy;
    end;
  private
    HTTP: TidHTTP;
    SSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
    FClientId: String;
    FClientSecret: String;
    FRefreshToken: String;
    FTokenType: String;
    FAccessToken: String;
    FTokenRefresh: TDateTime;
  public
    OnGetToken: TNotifyEvent;
    constructor Create;
    destructor Destroy;
    function Get(const AURL: String; Response: TStream; const ClearHeaders: Boolean = False): Boolean; overload;
    procedure Get(const AURL: String; OnGet: TOnGet = nil) overload;
    procedure GetFile(const AURL: String; FileToSave: String; pBarParams: TPBarParams;
      const CreatePBar: Boolean = False; OnGet: TOnGet = nil);
    procedure refreshToken;
  end;

const
  EmptyPBarParams : TPBarParams = (Top: 0; Left: 0; Width: 0; Height: 0;
    Anchors: []; AOwner: nil; Parent: nil; BeforeCreate: nil; AfterDestroy: nil; Size: 0);

implementation

{ TGoogle }

constructor TGoogle.Create;
begin
  inherited;
  SSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  HTTP := TidHTTP.Create(nil);
  HTTP.IOHandler := SSLIOHandler;
  HTTP.HandleRedirects := True;
  FTokenRefresh := NullDate;
  {$REGION 'Эти 3 параметра загружаются из модуля uPasswords'}
  FClientId := UClientId;
  FClientSecret := UClientSecret;
  FRefreshToken := URefreshToken;
  {$ENDREGION}
end;

destructor TGoogle.Destroy;
begin
  inherited;
  SSLIOHandler.Free;
  HTTP.Free;
end;

function TGoogle.Get(const AURL: String; Response: TStream; const ClearHeaders: Boolean): Boolean;
begin
  Result := False;
  try
    HTTP.Request.CustomHeaders.Clear;
    if not ClearHeaders then
    begin
      if (StrToInt(FormatDateTime('n', now - FTokenRefresh)) > 50) or
        (FormatDateTime('dd.mm.yyyy', now) <> FormatDateTime('dd.mm.yyyy', FTokenRefresh)) then
        refreshToken;

      HTTP.Request.CustomHeaders.Add('Authorization: ' + FTokenType
        + ' ' + FAccessToken);
    end;

    HTTP.Get(AURL, Response);
    Result := True;
  except
    on E: Exception do
      raise;
  end;
end;

procedure TGoogle.Get(const AURL: String; OnGet: TOnGet);
var
  GetThread: TGet;
begin
  try
    if (StrToInt(FormatDateTime('n', now - FTokenRefresh)) > 50) or
      (FormatDateTime('dd.mm.yyyy', now) <> FormatDateTime('dd.mm.yyyy', FTokenRefresh)) then
      refreshToken;

    GetThread := TGet.Create;
    GetThread.Priority := tpNormal;
    GetThread.TokenType := FTokenType;
    GetThread.AccessToken := FAccessToken;
    GetThread.OnGet := OnGet;
    GetThread.Url := AURL;
    GetThread.fName := EmptyStr;
    GetThread.CreatePBar := False;
    GetThread.pBarParams := EmptyPBarParams;
    GetThread.FreeOnTerminate := True;
    GetThread.Resume;

  except
    on E: Exception do
      raise;
  end;
end;

procedure TGoogle.GetFile(const AURL: String; FileToSave: String;
  pBarParams: TPBarParams; const CreatePBar: Boolean; OnGet: TOnGet);
var
  GetThread: TGet;
begin
  try
    if (StrToInt(FormatDateTime('n', now - FTokenRefresh)) > 50) or
      (FormatDateTime('dd.mm.yyyy', now) <> FormatDateTime('dd.mm.yyyy', FTokenRefresh)) then
      refreshToken;

    GetThread := TGet.Create;
    GetThread.Priority := tpNormal;
    GetThread.TokenType := FTokenType;
    GetThread.AccessToken := FAccessToken;
    GetThread.OnGet := OnGet;
    GetThread.Url := AURL;
    GetThread.fName := FileToSave;
    GetThread.CreatePBar := CreatePBar;
    GetThread.pBarParams := pBarParams;
    GetThread.FreeOnTerminate := True;
    GetThread.Resume;

  except
    on E: Exception do
      raise;
  end;
end;

procedure TGoogle.refreshToken;
var
  Params: TStringList;
  Response: TStringStream;
  jObj: TJSONObject;
begin
  Params := TStringList.Create;
  Params.Values['client_id'] := FClientId;
  Params.Values['client_secret'] := FClientSecret;
  Params.Values['refresh_token'] := FRefreshToken;
  Params.Values['grant_type'] := 'refresh_token';

  Response := TStringStream.Create;
  try
    HTTP.Post(cTokenURL, Params, Response);
    jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
    FAccessToken := (jObj.Get('access_token').JsonValue as TJSONString).Value;
    FTokenType := (jObj.Get('token_type').JsonValue as TJSONString).Value;
  finally
    Response.Free;
    Params.Free;
    FTokenRefresh := Now;
    if Assigned(OnGetToken) then
      OnGetToken(Self);
  end;
end;

{ TGoogle.TGet }

procedure TGoogle.TGet.Execute;
begin
  try
    SSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    HTTP := TidHTTP.Create(nil);
    HTTP.IOHandler := SSLIOHandler;
    HTTP.HandleRedirects := True;

    pBarCreated := False;
    if CreatePBar then
    begin
      Synchronize(pBarCreate);

      HTTP.OnWork := Work;
      HTTP.OnWorkEnd := WorkEnd;
    end;

    if Length(fName) > 0 then
    begin
      if FileExists(fName) then
        Stream := TFileStream.Create(fName, fmOpenReadWrite)
      else
        Stream := TFileStream.Create(fName, fmCreate);
    end
    else
      Stream := TMemoryStream.Create;

    HTTP.Request.CustomHeaders.Clear;
    HTTP.Request.CustomHeaders.Add('Authorization: ' + TokenType
      + ' ' + AccessToken);

    HTTP.Get(url, Stream);

    if CreatePBar then
      Synchronize(pBarDestroy);

    Synchronize(DoOnGet);
    Stream.Free;
    SSLIOHandler.Free;
    HTTP.Free;
  except
    on E: EIdHTTPProtocolException do
    begin
      ShowMessage(Format('Error %s(%d) happened. Message is: %s', [e.classname, e.ErrorCode, e.ErrorMessage]));
    end;
    on E: Exception do
    begin
      if pBarCreated and CreatePBar then
        Synchronize(pBarDestroy);
      raise;
      Self.Terminate;
    end;
  end;
end;

procedure TGoogle.TGet.DoOnGet;
begin
  if Assigned(OnGet) then
    OnGet(Stream);
end;

procedure TGoogle.TGet.pBarCreate;
begin
  if Assigned(pBarParams.BeforeCreate) then
    pBarParams.BeforeCreate(nil);
  pBar := TAdvSmoothProgressBar.Create(pBarParams.AOwner);
  pBarCreated := True;
  pBar.Parent := pBarParams.Parent;
  pBar.Left := pBarParams.Left;
  pBar.Top := pBarParams.Top;
  pBar.Width := pBarParams.Width;
  pBar.Height := pBarParams.Height;
  pBar.Anchors := pBarParams.Anchors;
  pBar.Maximum := pBarParams.Size;
  pBarMax := pBarParams.Size;

  pBar.Step := 1;
  with pBar do
  begin
    Appearance.BackGroundFill.Color := clHotLight;
    Appearance.BackGroundFill.ColorTo := clHotLight;
    Appearance.BackGroundFill.ColorMirror := clNone;
    Appearance.BackGroundFill.ColorMirrorTo := clNone;
    Appearance.BackGroundFill.BorderColor := clSilver;

    Appearance.ProgressFill.Color := clSkyBlue;
    Appearance.ProgressFill.ColorTo := clSkyBlue;
    Appearance.ProgressFill.ColorMirror := clSkyBlue;
    Appearance.ProgressFill.ColorMirrorTo := clSkyBlue;
    Appearance.ProgressFill.BorderColor := clSkyBlue;

  end;

  pBar.Appearance.ValueFormat := ExtractFileName(fName) + ' ' + pBar.Appearance.ValueFormat;
  pBar.Appearance.ValueVisible := True;
end;

procedure TGoogle.TGet.pBarDestroy;
var
  i: Integer;
begin
  FreeAndNil(pBar);
  pBarCreated := False;
  if Assigned(pBarParams.AfterDestroy) then
    pBarParams.AfterDestroy(pBarParams.Top, pBarParams.Left, pBarParams.Height, pBarParams.Width);
end;

procedure TGoogle.TGet.pBarWork;
begin
  if pBarMax > 0 then
    pBar.Position := 100 * pBarPos / pBarMax;
end;

procedure TGoogle.TGet.Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  pBarPos := AWorkCount;
  Synchronize(pBarWork);
end;

procedure TGoogle.TGet.pBarWorkEnd;
begin
  pBar.Position := pBarMax;
end;

procedure TGoogle.TGet.WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  Synchronize(pBarWorkEnd);
end;

end.
