object Preloader: TPreloader
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 118
  ClientWidth = 110
  Color = clWhite
  TransparentColorValue = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    110
    118)
  PixelsPerInch = 96
  TextHeight = 13
  object Img: TImage
    Left = 20
    Top = 8
    Width = 70
    Height = 70
    Anchors = [akTop]
    Transparent = True
    ExplicitLeft = 23
  end
  object Label1: TLabel
    Left = 19
    Top = 89
    Width = 72
    Height = 28
    Anchors = [akBottom]
    Caption = #1047#1072#1075#1088#1091#1079#1082#1072
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe Print'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitLeft = 34
    ExplicitTop = 111
  end
end
