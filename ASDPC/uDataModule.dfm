object Data: TData
  OldCreateOrder = False
  Height = 300
  Width = 387
  object Timer: TTimer
    Enabled = False
    Interval = 300000
    OnTimer = TimerTimer
    Left = 8
    Top = 8
  end
  object Tray: TTrayIcon
    BalloonTimeout = 10
    PopupMenu = Popup
    OnBalloonClick = ShowNewsClick
    OnClick = TrayClick
    OnDblClick = TrayClick
    Left = 48
    Top = 8
  end
  object Popup: TPopupMenu
    OnPopup = PopupPopup
    Left = 88
    Top = 8
    object tSeparator1: TMenuItem
      Caption = '--'#1043#1088#1091#1087#1087#1072'--'
      Enabled = False
    end
    object ShowNews: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1085#1086#1074#1086'c'#1090#1100
      OnClick = ShowNewsClick
    end
    object GoVK: TMenuItem
      Caption = #1055#1077#1088#1077#1081#1090#1080' '#1082' '#1075#1088#1091#1087#1087#1077
      OnClick = GoVKClick
    end
    object ShowTimeTable: TMenuItem
      Caption = #1055#1086#1082#1072#1079#1072#1090#1100' '#1088#1072#1089#1087#1080#1089#1072#1085#1080#1077
      OnClick = ShowTimeTableClick
    end
    object tSeparator2: TMenuItem
      Caption = '--'#1040#1074#1090#1086#1079#1072#1075#1088#1091#1079#1082#1072'--'
      Enabled = False
    end
    object AutorunOn: TMenuItem
      Caption = #1042#1082#1083#1102#1095#1080#1090#1100
      OnClick = AutorunOnClick
    end
    object AutorunOff: TMenuItem
      Caption = #1042#1099#1082#1083#1102#1095#1080#1090#1100
      OnClick = AutorunOffClick
    end
    object tSeparator3: TMenuItem
      Caption = '--'#1054#1073#1085#1086#1074#1083#1077#1085#1080#1103'--'
      Enabled = False
    end
    object chkUpdate: TMenuItem
      Caption = #1055#1088#1086#1074#1077#1088#1080#1090#1100' '#1086#1073#1085#1086#1074#1083#1077#1085#1080#1103
      OnClick = chkUpdateClick
    end
    object ShowWatsNew: TMenuItem
      Caption = #1063#1090#1086' '#1085#1086#1074#1086#1075#1086
      OnClick = ShowWatsNewClick
    end
    object tSeparator4: TMenuItem
      Caption = '--Google Drive--'
      Enabled = False
    end
    object ShowGDrive: TMenuItem
      Caption = #1054#1090#1082#1088#1099#1090#1100' GDrive'
      OnClick = ShowGDriveClick
    end
    object Separator: TMenuItem
      Caption = '-'
    end
    object Exit: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = ExitClick
    end
  end
  object RepeatNews: TTimer
    Enabled = False
    Interval = 300000
    OnTimer = RepeatNewsTimer
    Left = 144
    Top = 8
  end
  object CheckUpdate: TTimer
    Enabled = False
    Interval = 3600000
    OnTimer = CheckUpdateTimer
    Left = 216
    Top = 8
  end
  object AuthShow: TTimer
    Enabled = False
    Interval = 100
    OnTimer = AuthShowTimer
    Left = 8
    Top = 72
  end
  object Wait: TTimer
    Enabled = False
    OnTimer = WaitTimer
    Left = 72
    Top = 72
  end
  object Save: TSaveDialog
    Left = 8
    Top = 128
  end
end
