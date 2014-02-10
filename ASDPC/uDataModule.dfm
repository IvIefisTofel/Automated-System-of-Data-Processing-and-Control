object Data: TData
  OldCreateOrder = False
  Height = 289
  Width = 140
  object Tray: TTrayIcon
    BalloonTimeout = 10
    PopupMenu = Popup
    OnBalloonClick = ShowNewsClick
    OnClick = TrayClick
    OnDblClick = TrayClick
    Left = 16
    Top = 8
  end
  object Popup: TPopupMenu
    OnPopup = PopupPopup
    Left = 16
    Top = 64
    object bSeparator1: TMenuItem
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
    object bSeparator2: TMenuItem
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
    object bSeparator3: TMenuItem
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
    object bSeparator4: TMenuItem
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
  object Save: TSaveDialog
    Left = 16
    Top = 120
  end
end
