unit uDataModule;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.UITypes, System.StrUtils,
  Vcl.Menus, Vcl.ExtCtrls, Vcl.Dialogs,
  ShellAPI, AutorunReg, Registry, DBXJSON,
  GifImg, PNGImage, Jpeg,
  uGoogle, uHelper;

type
  TData = class(TDataModule)
    Tray: TTrayIcon;
    Popup: TPopupMenu;
    bSeparator1: TMenuItem;
    ShowNews: TMenuItem;
    GoVK: TMenuItem;
    bSeparator2: TMenuItem;
    AutorunOn: TMenuItem;
    AutorunOff: TMenuItem;
    Separator: TMenuItem;
    Exit: TMenuItem;
    bSeparator3: TMenuItem;
    chkUpdate: TMenuItem;
    ShowTimeTable: TMenuItem;
    ShowWatsNew: TMenuItem;
    bSeparator4: TMenuItem;
    ShowGDrive: TMenuItem;
    Save: TSaveDialog;
    procedure PopupPopup(Sender: TObject);
    procedure ShowNewsClick(Sender: TObject);
    procedure GoVKClick(Sender: TObject);
    procedure AutorunOnClick(Sender: TObject);
    procedure AutorunOffClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure chkUpdateClick(Sender: TObject);
    procedure ShowTimeTableClick(Sender: TObject);
    procedure ShowWatsNewClick(Sender: TObject);
    procedure ShowGDriveClick(Sender: TObject);
  protected
    FImgae: TImage;
    FUrl: String;
  private
    function GetAutoRun: Boolean;
    procedure SetAutoRun(Value: Boolean);
    procedure OnGetImage(Stream: TMemoryStream);
  public
    procedure downloadImage(url: String; Image: TImage);
    property AutoRun: Boolean read GetAutoRun write SetAutoRun;
  end;

var
  TimeTokenRefresh: TDateTime = -7274; // null
  NewsLoaded: Boolean = False;

implementation

uses uMain;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

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
  ShellExecute(0, 'open', PChar('http://vk.com/club' + user.groupID), nil, nil, SW_SHOW);
end;

procedure TData.ShowTimeTableClick(Sender: TObject);
begin
  TimeTable.updateTimeTable(True);
end;

procedure TData.ShowWatsNewClick(Sender: TObject);
begin
  WatsNew.updateWatsNew(True);
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

procedure TData.ShowGDriveClick(Sender: TObject);
begin
  Drive.Show;
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
  ShowTimeTable.Enabled := TimeTableLoaded;
  ShowWatsNew.Enabled := WatsNewLoaded;
end;

{ updateNews }

procedure TData.OnGetImage(Stream: TMemoryStream);
var
  sImgExt: String;
  jImg: TJPEGImage;
  pImg: TPngImage;
  gImg: TGIFImage;
begin
  sImgExt := LowerCase(ExtractFileExt(FUrl));
  Stream.Position := 0;
  if (sImgExt = '.jpg') or (sImgExt = '.jpeg') then
  begin
    jImg := TJPEGImage.Create;
    jImg.LoadFromStream(Stream);
    FImgae.Picture.Assign(jImg);
    jImg.Free;
  end else
  if (sImgExt = '.png') then
  begin
    pImg := TPngImage.Create;
    pImg.LoadFromStream(Stream);
    FImgae.Picture.Assign(pImg);
    pImg.Free;
  end else
  if (sImgExt = '.gif') then
  begin
    gImg := TGIFImage.Create;
    gImg.LoadFromStream(Stream);
    gImg.Animate := False;
    FImgae.Picture.Assign(gImg);
    gImg.Free;
  end;
  FUrl := '';
end;

procedure TData.downloadImage(url: String; Image: TImage);
begin
  FImgae := Image;
  FUrl := url;
  Google.Get(url, OnGetImage);
end;

end.
