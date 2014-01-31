object Main: TMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ASDPC Uninstaller'
  ClientHeight = 127
  ClientWidth = 259
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    259
    127)
  PixelsPerInch = 96
  TextHeight = 13
  object DelBtn: TBitBtn
    Left = 45
    Top = 43
    Width = 169
    Height = 41
    Anchors = []
    Caption = #1059#1076#1072#1083#1080#1090#1100' ASDPC'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Segoe Print'
    Font.Style = [fsBold]
    Kind = bkOK
    NumGlyphs = 2
    ParentFont = False
    TabOrder = 0
    OnClick = DelBtnClick
  end
end
