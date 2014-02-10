unit uPreloader;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls,
  GIFImg;

type
  TPreloader = class(TForm)
    Img: TImage;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses uMain;

{$R *.dfm}

procedure TPreloader.FormCreate(Sender: TObject);
var
  Res: TResourceStream;
  Gif: TGIFImage;
begin
  Res:=TResourceStream.Create(Hinstance, 'Preloader', 'IMAGE');
  Gif := TGIFImage.Create;
  Gif.LoadFromStream(Res);
  Res.Free;

  Gif.Animate := true;
  Img.Picture.Assign(Gif);
  Gif.Free;
  Show;
end;

procedure TPreloader.FormShow(Sender: TObject);
begin
  Main.ShowTaskBar;
end;

procedure TPreloader.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  bClose := True;
  Main.Close;
end;

end.
