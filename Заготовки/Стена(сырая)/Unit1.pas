unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DBXJSON, Vcl.Grids, AdvObj, BaseGrid,
  AdvGrid, GifImg, PNGImage, Jpeg, ssl_openssl, httpsend;

type
  TForm1 = class(TForm)
    AdvStringGrid1: TAdvStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure AdvStringGrid1ControlClick(Sender: TObject; ARow, ACol: Integer;
      CtrlID, CtrlType, CtrlVal: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  jWall: TJSONArray;

implementation

uses unit2;

{$R *.dfm}

procedure downloadImage(url: String; Imgae: TBitmap);
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
    Imgae.Assign(jImg);
    jImg.Free;
  end else
  if (sImgExt = '.png') then
  begin
    pImg := TPngImage.Create;
    pImg.LoadFromStream(fImg);
    Imgae.Assign(pImg);
    pImg.Free;
  end else
  if (sImgExt = '.gif') then
  begin
    gImg := TGIFImage.Create;
    gImg.LoadFromStream(fImg);
    gImg.Animate := False;
    Imgae.Assign(gImg);
    gImg.Free;
  end;
  fImg.Free;
  fHTTP.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  jText: TStringList;
  jMedia: TJSONArray;
  haveMedia: Boolean;
  i, mediaIndex: Integer;
  typeMedia: String;
begin
  jText := TStringList.Create;

  jText.LoadFromFile('..\..\json.txt');
  jWall := (TJSONObject.ParseJSONValue(jText.Text) as TJSONObject).Get('response').JsonValue as TJSONArray;

  AdvStringGrid1.RowCount := (jWall.Size - 1) * 2;
  for i := 1 to jWall.Size - 1 do
  begin
    jText.Text := ((jWall.Get(i) as TJSONObject).Get('text').JsonValue as TJSONString).Value;
    AdvStringGrid1.Cells[0, (i - 1) * 2] := jText.Text;
    if (jWall.Get(i) as TJSONObject).Get('attachments') <> nil then
    begin
      jMedia := (jWall.Get(i) as TJSONObject).Get('attachments').JsonValue as TJSONArray;
      for mediaIndex := 0 to jMedia.Size - 1 do
      begin
        typeMedia := ((jMedia.Get(mediaIndex) as TJSONObject).Get('type').JsonValue as TJSONString).Value;
        if (typeMedia = 'photo') or (typeMedia = 'posted_photo') then
        begin
          AdvStringGrid1.Cells[0, (i - 1) * 2] := AdvStringGrid1.Cells[0, (i - 1) * 2] + '<control type="button" width="80" value="Изображение" id="'+
          (((jMedia.Get(mediaIndex) as TJSONObject).Get(typeMedia).JsonValue as TJSONObject).Get('src_big').JsonValue as TJSONString).Value+'">';
        end else
        if (typeMedia = 'video') then
        begin

        end else
        if (typeMedia = 'audio') then
        begin

        end else
        if (typeMedia = 'doc') then
        begin

        end else
        if (typeMedia = 'link') then
        begin

        end;
      end;
    end;

//    AdvStringGrid1.Cells[0, (i - 1) * 2] :=
  end;
  AdvStringGrid1.AutoSizeRows(False, 5);
  jText.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  AdvStringGrid1.AutoSizeRows(False, 5);
end;

procedure TForm1.AdvStringGrid1ControlClick(Sender: TObject; ARow,
  ACol: Integer; CtrlID, CtrlType, CtrlVal: string);
var
  img: TBitmap;
begin
  ShowMessage(CtrlType+#13#10+CtrlVal+#13#10+CtrlID);
//  if CtrlType = 'button' then
//    if CtrlVal = 'Изображение' then
//    begin
//      img := TBitmap.Create;
//      downloadImage(CtrlID, img);
//      Form2.Image1.Picture.Bitmap := img;
//      img.Free;
//
//      Form2.ClientHeight := Form2.Image1.Height + 16;
//      Form2.ClientWidth := Form2.Image1.Width + 16;
//      Form2.Position := poScreenCenter;
//      Form2.Show;
//    end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  jWall.Free;
end;

end.
