unit uLoading;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, GIFImg;

type
  TLoading = class(TForm)
    Preloader: TImage;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Loading: TLoading;

implementation

{$R *.dfm}

procedure TLoading.FormCreate(Sender: TObject);
var
  Res: TResourceStream;
  Gif: TGIFImage;
begin
  Res:=TResourceStream.Create(Hinstance, 'Preloader', 'IMAGE');
  Gif := TGIFImage.Create;
  Gif.LoadFromStream(Res);
  Res.Free;

  Gif.Animate := true;
  Preloader.Picture.Assign(Gif);
  Gif.Free;
end;

end.
