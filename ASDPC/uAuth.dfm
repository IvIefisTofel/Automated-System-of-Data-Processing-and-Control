object Auth: TAuth
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1040#1074#1090#1086#1088#1080#1079#1072#1094#1080#1103
  ClientHeight = 85
  ClientWidth = 180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  DesignSize = (
    180
    85)
  PixelsPerInch = 96
  TextHeight = 13
  object btnLogin: TBitBtn
    Left = 46
    Top = 48
    Width = 89
    Height = 25
    Anchors = [akTop]
    Caption = '&'#1042#1093#1086#1076
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 1
    OnClick = btnLoginClick
    ExplicitLeft = 29
  end
  object Remember_Me: TCheckBox
    Left = 15
    Top = 12
    Width = 151
    Height = 17
    Anchors = [akTop]
    Caption = #1047#1072#1087#1086#1084#1085#1080#1090#1100' '#1084#1077#1085#1103
    Checked = True
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe Print'
    Font.Style = [fsBold]
    ParentFont = False
    State = cbChecked
    TabOrder = 0
  end
  object Server: TServerSocket
    Active = False
    Port = 9004
    ServerType = stNonBlocking
    OnClientRead = ServerClientRead
    Left = 8
    Top = 8
  end
end
