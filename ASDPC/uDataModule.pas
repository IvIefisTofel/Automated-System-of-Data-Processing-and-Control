unit uDataModule;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.UITypes, System.StrUtils,
  Vcl.Menus, Vcl.ExtCtrls, Vcl.Dialogs,
  ShellAPI, AutorunReg, Registry, DBXJSON,
  lib, ssl_openssl, httpsend,
  GifImg, PNGImage, Jpeg, Google.OAuth;

const
  cFilePairs: array [0 .. 4] of string = ('clientSecret', 'redirectUri',
    'state', 'loginHint', 'tokenInfo');

  groupId = '57893525';

type
  TPostData = record
    PostID: Integer;
    LastDate: Integer
  end;

  TData = class(TDataModule)
    Timer: TTimer;
    Tray: TTrayIcon;
    Popup: TPopupMenu;
    tSeparator1: TMenuItem;
    ShowNews: TMenuItem;
    GoVK: TMenuItem;
    tSeparator2: TMenuItem;
    AutorunOn: TMenuItem;
    AutorunOff: TMenuItem;
    Separator: TMenuItem;
    Exit: TMenuItem;
    RepeatNews: TTimer;
    CheckUpdate: TTimer;
    tSeparator3: TMenuItem;
    chkUpdate: TMenuItem;
    AuthShow: TTimer;
    gOAuth: TOAuthClient;
    procedure PopupPopup(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure RepeatNewsTimer(Sender: TObject);
    procedure ShowNewsClick(Sender: TObject);
    procedure GoVKClick(Sender: TObject);
    procedure AutorunOnClick(Sender: TObject);
    procedure AutorunOffClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure CheckUpdateTimer(Sender: TObject);
    procedure chkUpdateClick(Sender: TObject);
    procedure AuthShowTimer(Sender: TObject);
  private
    function GetAutoRun: Boolean;
    procedure SetAutoRun(Value: Boolean);
  public
    procedure RefreshToken;
    function ReadDate: TPostData;
    procedure SaveDate(Data: TPostData);
    function replaceText(text: String): String;
    procedure formatNews;
    procedure downloadImage(url: String; Imgae: TImage);
    property AutoRun: Boolean read GetAutoRun write SetAutoRun;
  end;

var
  Data: TData;

implementation

uses uMain, uAuth, uHelper;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TData.RefreshToken;
var
  AJSONValue: TJSONValue;
  Enum: TJSONPairEnumerator;
begin
  AJSONValue := TJSONObject.ParseJSONValue(json);
  if Assigned(AJSONValue) then
  try
    Enum := TJSONObject(AJSONValue).GetEnumerator;
    try
      while Enum.MoveNext do
        with Enum.Current do
          case AnsiIndexStr(JsonString.Value, cFilePairs) of
            0: gOAuth.ClientSecret := JsonValue.Value;
            1: gOAuth.RedirectURI := JsonValue.Value;
            2: gOAuth.State := JsonValue.Value;
            3: gOAuth.LoginHint := JsonValue.Value;
            4: gOAuth.TokenInfo.Parse(TJSONObject(JsonValue).ToString);
          end;
      gOAuth.RefreshToken;
    finally
      Enum.Free
    end;
  finally
    AJSONValue.Free;
  end;
end;

function TData.GetAutoRun: Boolean;
begin
  Result := AutorunReg.AutorunCheckReg;
end;

procedure TData.SetAutoRun(Value: Boolean);
begin
  if AutoRun then
    AutorunReg.AutorunRemoveReg
  else
    AutorunReg.AutorunAddReg;
end;

procedure TData.TimerTimer(Sender: TObject);
begin
  formatNews;
end;

procedure TData.RepeatNewsTimer(Sender: TObject);
begin
  if HaveRead then
    Data.RepeatNews.Enabled := False;
  Data.Tray.ShowBalloonHint;
end;

procedure TData.AuthShowTimer(Sender: TObject);
var
  Reg: TRegistry;
begin
  AuthShow.Enabled := False;

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;

  if Reg.KeyExists('\Software\ASDPC') then
  begin
    Reg.OpenKey('\Software\ASDPC', False);
    Reg.DeleteValue('Login');
    Reg.DeleteValue('Password');
  end;

  Reg.CloseKey;
  Reg.Free;

  user := Auth.FindMe;
  if not ((user.access_token= 'nil') and (user.userId = 'nil')) then
  begin
    if Auth.VK_Valid then
    begin
      Tray.Visible := True;
      Timer.Enabled := True;
      CheckUpdate.Enabled := True;
      formatNews;
    end else
      Auth.Show;
  end else
    Auth.Show;
end;

procedure TData.CheckUpdateTimer(Sender: TObject);
begin
  Main.checkUpdate;
end;

procedure TData.TrayClick(Sender: TObject);
begin
  if Data.Tray.BalloonHint <> '' then
    Data.Tray.ShowBalloonHint;
end;

procedure TData.ShowNewsClick(Sender: TObject);
begin
  Main.showNews;
end;

procedure TData.GoVKClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://vk.com/asouy2013', nil, nil, SW_SHOW);
end;

procedure TData.AutorunOnClick(Sender: TObject);
begin
  AutoRun := True;
end;

procedure TData.AutorunOffClick(Sender: TObject);
begin
  AutoRun := False;
end;

procedure TData.chkUpdateClick(Sender: TObject);
begin
  Main.checkUpdate(True);
end;

procedure TData.ExitClick(Sender: TObject);
begin
  bClose := True;
  Main.Close;
end;

procedure TData.PopupPopup(Sender: TObject);
begin
  AutorunOn.Enabled := not AutoRun;
  AutorunOff.Enabled := AutoRun;
end;

{ updateNews }

function TData.ReadDate: TPostData;
var
  R: TRegistry;
begin
  Result.LastDate := 0;
  Result.PostID := 0;

  R := TRegistry.Create;
  R.RootKey := HKEY_CURRENT_USER;

  R.OpenKey('\Software\ASDPC',True);
  if R.ValueExists('Date') then
    Result.LastDate := R.ReadInteger('Date');
  if R.ValueExists('PostID') then
    Result.PostID := R.ReadInteger('PostID');

  R.CloseKey;
  R.Free;
end;

procedure TData.SaveDate(Data: TPostData);
var
  R: TRegistry;
begin
  R := TRegistry.Create;
  R.RootKey := HKEY_CURRENT_USER;

  R.OpenKey('\Software\ASDPC',True);
  R.WriteInteger ('Date', Data.LastDate);
  R.WriteInteger('PostID', Data.PostID);

  R.CloseKey;
  R.Free;
end;

function TData.replaceText(text: String): String;
var
  offset: Integer;
begin
  text := StringReplace(text, '<br>', #13#10, [rfReplaceAll, rfIgnoreCase]);

  offset := 1;
  while Pos('\', text, offset) <> 0 do
  begin
    offset := offset + 2;
    Delete(text, Pos('\', text, offset), 1);
  end;

  Result := text;
end;

procedure TData.downloadImage(url: String; Imgae: TImage);
var
  fHTTP: THTTPSend;
  sImgExt: String;
  fImg: TMemoryStream;
  jImg: TJPEGImage;
  pImg: TPngImage;
  gImg: TGIFImage;
begin
  fHTTP := THTTPSend.Create;
  fImg := TMemoryStream.Create;
  HttpGetBinary(url, fImg);
  sImgExt := LowerCase(ExtractFileExt(url));
  fImg.Position := 0;
  if (sImgExt = '.jpg') or (sImgExt = '.jpeg') then
  begin
    jImg := TJPEGImage.Create;
    jImg.LoadFromStream(fImg);
    Imgae.Picture.Assign(jImg);
    jImg.Free;
  end else
  if (sImgExt = '.png') then
  begin
    pImg := TPngImage.Create;
    pImg.LoadFromStream(fImg);
    Imgae.Picture.Assign(pImg);
    pImg.Free;
  end else
  if (sImgExt = '.gif') then
  begin
    gImg := TGIFImage.Create;
    gImg.LoadFromStream(fImg);
    gImg.Animate := False;
    Imgae.Picture.Assign(gImg);
    gImg.Free;
  end;
  fImg.Free;
  fHTTP.Free;
end;

procedure TData.formatNews;
const
  TrayLimit = 150;

var
  jObj: TJSONObject;
  jArr: TJSONArray;
  text: TStringList;
  toTray: String;
begin
  Response := UTF8ToString(send('GET', 'https://api.vk.com/method/wall.get?owner_id=-57893525&count=1&access_token=' + user.access_token));
  jObj := TJSONObject.ParseJSONValue(Response) as TJSONObject;
  if Assigned(jObj) then
  begin
    jArr := jObj.Get(0).JsonValue as TJSONArray;
    Data.Tray.BalloonTitle := (jArr.Get(0) as TJSONString).Value + ' записей.';

    jObj := jArr.Get(1) as TJSONObject;
    newData.PostID := (jObj.Get('id').JsonValue as TJSONNumber).AsInt;
    newData.LastDate := (jObj.Get('date').JsonValue as TJSONNumber).AsInt;
    text := TStringList.Create;
    text.Text := (jObj.Get('text').JsonValue as TJSONString).Value;

    text.Text := replaceText(text.Text);
    if Length(text.Text) > TrayLimit then
      toTray := Copy(text.Text, 1, TrayLimit) + '...'
    else
      toTray := text.Text;

    Data.Tray.BalloonHint := toTray;
    Main.Post.Text := text.Text;
  end;

  oldData := ReadDate;
  if not ((oldData.LastDate = 0) and (oldData.PostID = 0)) then
  begin
    if (newData.PostID <> oldData.PostID) or (newData.LastDate <> oldData.LastDate) then
    begin
      HaveRead := False;
      Data.Tray.ShowBalloonHint;
      Data.RepeatNews.Enabled := True;
    end else
      HaveRead := True;
  end else
  begin
    HaveRead := False;
    Data.Tray.ShowBalloonHint;
    Data.RepeatNews.Enabled := True;
  end;
end;

end.
