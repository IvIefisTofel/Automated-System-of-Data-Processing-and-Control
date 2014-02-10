unit uNewsLoader;

interface

uses
  Windows, SysUtils, Classes, ScktCOMP , DBXJSON, uGoogle, uHelper, Dialogs,
  Registry;

type
  TPostData = record
    PostID: Integer;
    LastDate: Integer
  end;

  TNewsLoader = class(TThread)
  protected
    procedure Execute; override;
  end;

  TLoadNews = class(TThread)
  private
    jObj: TJSONObject;
    jArr: TJSONArray;
    Response: TStringStream;
  protected
    procedure Execute; override;
    procedure GetNews;
    procedure ParseNews;
  end;

  TRepeatNews = class(TThread)
  protected
    procedure Execute; override;
    procedure ShowBallonHint;
  end;

  function ReadPostDate: TPostData;
  procedure SavePostDate(Data: TPostData);

implementation

uses uMain, uDataModule;

function replaceText(text: String): String;
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

function ReadPostDate: TPostData;
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

procedure SavePostDate(Data: TPostData);
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

{ TNewsLoader }

procedure TNewsLoader.Execute;
var
  LoadNews: TLoadNews;
begin
  while not Terminated do
  begin
    LoadNews := TLoadNews.Create(True);
    LoadNews.Priority := tpNormal;
    LoadNews.FreeOnTerminate := True;
    LoadNews.Resume;
    Sleep(300000);
  end;
end;

{ TLoadNews }

procedure TLoadNews.Execute;
begin
  try
    if user.groupID = gID then
      TimeTable.updateTimeTable;
    WatsNew.updateWatsNew;

    Response := TStringStream.Create;
    Synchronize(GetNews);
    jObj := TJSONObject.ParseJSONValue(UTF8ToString(Response.DataString)) as TJSONObject;
    if Assigned(jObj) then
    begin
      Synchronize(ParseNews);
    end;

    oldData := ReadPostDate;
    if not ((oldData.LastDate = 0) and (oldData.PostID = 0)) then
    begin
      if (newData.PostID <> oldData.PostID) or (newData.LastDate <> oldData.LastDate) then
      begin
        RepeatNews.Resume;
      end else
        RepeatNews.Suspend;
    end else
      RepeatNews.Resume;
    NewsLoaded := True;
    Response.Free;
  except
    on E:Exception do
      Terminate;
  end;
end;

procedure TLoadNews.GetNews;
begin
  Google.Get('https://api.vk.com/method/wall.get?owner_id=-' + user.groupID + '&count=1&access_token=' + user.access_token, Response, True);
end;

procedure TLoadNews.ParseNews;
const
  TrayLimit = 150;

var
  Text: TStringList;
  toTray: String;
begin
  jArr := jObj.Get(0).JsonValue as TJSONArray;
  Data.Tray.BalloonTitle := (jArr.Get(0) as TJSONString).Value + ' записей.';

  jObj := jArr.Get(1) as TJSONObject;
  newData.PostID := (jObj.Get('id').JsonValue as TJSONNumber).AsInt;
  newData.LastDate := (jObj.Get('date').JsonValue as TJSONNumber).AsInt;
  Text := TStringList.Create;
  Text.Text := (jObj.Get('text').JsonValue as TJSONString).Value;

  Text.Text := replaceText(Text.Text);
  if Length(Text.Text) > TrayLimit then
    toTray := Copy(Text.Text, 1, TrayLimit) + '...'
  else
    toTray := Text.Text;

  Data.Tray.BalloonHint := toTray;
  Main.Post.Text := text.Text;
  if not Data.Tray.Visible then
  begin
    Data.Tray.Visible := True;
    Preloader.Destroy;
  end;
end;

{ TRepeatNews }

procedure TRepeatNews.Execute;
begin
  while not Terminated do
  begin
    Synchronize(ShowBallonHint);
    Sleep(300000);
  end;
end;

procedure TRepeatNews.ShowBallonHint;
begin
  Data.Tray.ShowBalloonHint;
end;

end.
