object Data: TData
  OldCreateOrder = False
  Height = 234
  Width = 358
  object gOAuth: TOAuthClient
    RedirectURI = 'urn:ietf:wg:oauth:2.0:oob'
    TokenInfo.DriveScopes.FullAccess = True
    TokenInfo.DriveScopes.Readonly = False
    TokenInfo.DriveScopes.FileAccess = False
    TokenInfo.DriveScopes.AppsReadonly = False
    TokenInfo.DriveScopes.ReadonlyMetadata = False
    TokenInfo.DriveScopes.Install = False
    TokenInfo.DriveScopes.Appdata = False
    TokenInfo.CalendarScopes.FullAccess = False
    TokenInfo.CalendarScopes.Readonly = False
    TokenInfo.TasksScopes.FullAccess = False
    TokenInfo.TasksScopes.Readonly = False
    SaveFields = [sfClientSecret, sfRedirectURI, sfState, sfLoginHint]
    DefaultContentType = ctJSON
    ValidateOnLoad = False
    OpenStartURL = False
    Left = 8
    Top = 8
  end
end
