object WatsNew: TWatsNew
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'WatsNew'
  ClientHeight = 510
  ClientWidth = 651
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    651
    510)
  PixelsPerInch = 96
  TextHeight = 13
  object LabelWatsNew: TLabel
    Left = 8
    Top = 8
    Width = 125
    Height = 31
    Anchors = [akLeft, akBottom]
    Caption = #1063#1090#1086' '#1085#1086#1074#1086#1075#1086':'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Segoe Script'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object News: TRichEdit
    Left = 8
    Top = 40
    Width = 635
    Height = 433
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe Print'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Ok: TBitBtn
    Left = 528
    Top = 479
    Width = 115
    Height = 25
    Anchors = [akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe Script'
    Font.Style = [fsBold]
    Kind = bkOK
    NumGlyphs = 2
    ParentFont = False
    TabOrder = 1
    OnClick = OkClick
  end
end
