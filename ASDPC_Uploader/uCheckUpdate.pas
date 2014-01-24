unit uCheckUpdate;

interface

uses
  Winapi.Windows, SysUtils, System.Classes, Vcl.Dialogs, Registry, IniFiles,
  ActiveX;

type
  TCheckUpdate = class(TThread)
  private
    logStr: String;
  public
    startThread: Boolean;
  protected
    procedure Execute; override;
    procedure logThat;
    procedure assignImg;
  end;

implementation

uses GifImg, uMain, uThread, uASDP_Update;

{ TCheckUpdate }

procedure TCheckUpdate.Execute;
var
  Str: string;
  My: TMyThread;
begin
  Synchronize(assignImg);
  Synchronize(Main.preloaderShow);

  logStr :='Подклучение к серверу..';
  Synchronize(logThat);

  userApp := TUserApp.Create;
  WebDAV := TWebDAVSend.Create;
  Resources := TWDResourceList.Create;

  try
    Resources.Clear;
    Str := WebDAV.PROPFIND(1, '');
    if Length(Trim(Str)) > 0 then
    begin
      CoInitialize(nil);
      ParseResources(Str);
      CoUninitialize;
    end else
    begin
      Synchronize(Main.Log.Clear);
      logStr :='Ошибка подключения к серверу..';
      Synchronize(logThat);
      Synchronize(Main.exitCaption);
    end;

    if startThread then
    begin
      My := TMyThread.Create(True);
      My.Priority := tpNormal;
      My.FreeOnTerminate := True;
      My.Resume;
    end else
    begin
      Synchronize(Main.Log.Clear);
      Synchronize(Main.preloaderHide);
    end;
  except
    on E:Exception do
    begin
      Synchronize(Main.Log.Clear);
      logStr :='Ошибка подключения к серверу..';
      Synchronize(logThat);
      Synchronize(Main.exitCaption);
      Synchronize(Main.preloaderHide);
    end;
  end;
end;

procedure TCheckUpdate.assignImg;
var
  Res: TResourceStream;
  Gif: TGIFImage;
  My: TMyThread;
begin
  Res:=TResourceStream.Create(Hinstance, 'Preloader', 'IMAGE');
  Gif := TGIFImage.Create;
  Gif.LoadFromStream(Res);
  Res.Free;

  Gif.Animate := true;
  Main.Preloader.Picture.Assign(Gif);
  Gif.Free;
end;

procedure TCheckUpdate.logThat;
begin
  Main.Log.Items.Add(logIndent + logStr);
end;

end.
