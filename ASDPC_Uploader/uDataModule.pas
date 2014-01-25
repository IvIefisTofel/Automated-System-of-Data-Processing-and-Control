unit uDataModule;

interface

uses
  Classes, Windows, ActiveX, ShlObj, ShellAPI, SysUtils, ComObj, Forms,
  StrUtils,
  Google.OAuth, DBXJSON;

const
  cFilePairs: array [0 .. 4] of string = ('clientSecret', 'redirectUri',
    'state', 'loginHint', 'tokenInfo');

type
  TData = class(TDataModule)
    gOAuth: TOAuthClient;
  private
  public
    procedure RefreshToken;
  end;

var
  Data: TData;

implementation

uses uHelper;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TData.RefreshToken;
var
  AJSONValue: TJSONValue;
  Enum: TJSONPairEnumerator;
begin
  AJSONValue := TJSONObject.ParseJSONValue(json);
  if Assigned(AJSONValue) then
  try
    Enum := TJSONObject(AJSONValue).GetEnumerator;
    try
      while Enum.MoveNext do
        with Enum.Current do
          case AnsiIndexStr(JsonString.Value, cFilePairs) of
            0: gOAuth.ClientSecret := JsonValue.Value;
            1: gOAuth.RedirectURI := JsonValue.Value;
            2: gOAuth.State := JsonValue.Value;
            3: gOAuth.LoginHint := JsonValue.Value;
            4: gOAuth.TokenInfo.Parse(TJSONObject(JsonValue).ToString);
          end;
      gOAuth.RefreshToken;
    finally
      Enum.Free
    end;
  finally
    AJSONValue.Free;
  end;
end;

end.
