object Main: TMain
  Left = 0
  Top = 0
  BorderIcons = [biMinimize, biMaximize]
  BorderStyle = bsNone
  ClientHeight = 477
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
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    651
    477)
  PixelsPerInch = 96
  TextHeight = 13
  object GoToGroup: TLabel
    Left = 8
    Top = 445
    Width = 149
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1077#1088#1077#1081#1090#1080' '#1082' '#1075#1088#1091#1087#1087#1077
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Segoe Script'
    Font.Style = [fsBold]
    ParentFont = False
    ExplicitTop = 306
  end
  object Avatar: TImage
    Left = 8
    Top = 8
    Width = 100
    Height = 100
  end
  object UserInfo: TLabel
    Left = 114
    Top = 8
    Width = 399
    Height = 100
    AutoSize = False
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe Script'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object Ok: TBitBtn
    Left = 528
    Top = 445
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
    TabOrder = 0
    OnClick = OkClick
    ExplicitTop = 306
  end
  object Post: TRichEdit
    Left = 8
    Top = 114
    Width = 635
    Height = 325
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Segoe Print'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitHeight = 310
  end
end
