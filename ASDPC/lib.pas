unit lib;

interface
//by IMREADYOURMIND v 1.5
uses httpsend,ssl_openssl, forms,dialogs,Classes, Messages, SysUtils, Controls,
   ExtCtrls, StdCtrls, SHDocVw, ComCtrls,syncobjs,strutils;
	//отправка запросов
  function Send(method,url:string;postParams:string='';cookie:string='';showCookie:boolean=false;proxyType:string='';proxy:string='';proxyUser:string='';proxyPass:string='';files:string='';userAgent:string='';referer:string=''):string;
  function FoundLocationStrNum(str:string;Headers: TStringlist): integer;
  //разбитие строки по разделителю
  procedure Explode(var a: array of string; Border, S: string);
  //скачка и сохранение файла по ссылке
  function DwFi(SourceFile, DestFile: string;cookie:string=''): Boolean;
  //урленкод перевод кирилицы в ulr формат
  function URLEncode(const S2: string): string; 
  //замена в строке
  function ReplaceSub(str, sub1, sub2: string): string; 
  //парсер любой строки
  function parser(doc,home,eend:string;nacpos:integer=0;parstype:integer=0):string; 
  //Отправление капчи в антигейт в ответ придет ID
  function captchaStart(path,key:string):string; 
  // прием капчи в ответ приходит капча
  function captchaFinish(id,key:string):string;
implementation


function captchaStart(path,key:string):string;
var res:string;
begin
  res:=send('POST','http://antigate.com/in.php','method=post&soft_id=290&key='+key+'&is_russian=2','',false,'','','','','file,'+trim(path)+',image\pjpg');
  result:=Trim(parser(res, '|', #13#10));
end;

function captchaFinish(id,key:string):string;
var text:string;
begin
  text:=send('GET','http://antigate.com/res.php?key='+key+'&action=get&id='+id);
  if trim(text)='CAPCHA_NOT_READY'  then begin
    result:='';
  end else
    result:=trim(Copy(text, 4, Length(text) - 3));
    result:=urlencode(result);
end;

function parser(doc,home,eend:string;nacpos:integer=0;parstype:integer=0):string;
var raz:integer;
begin
  if parstype=0 then begin
    if ((trim(home)<>'') and (trim(eend)='')) then begin
      result:=copy(doc,posex(home,doc,nacpos)+length(home),length(doc)-(posex(home,doc,nacpos)+length(home))+1);
    end else if ((trim(home)='') and (trim(eend)<>'')) then begin
      result:=copy(doc,1,posex(eend,doc,nacpos)-1);
    end else if ((trim(home)<>'') and (trim(eend)<>'')) then begin
      if copy(doc,posex(home,doc,nacpos)+length(home),1)<>copy(eend,1,1) then begin
        raz:=posex(eend,doc,posex(home,doc,nacpos)+length(home)+1)-posex(home,doc,nacpos)-length(home);
        result:=copy(doc,posex(home,doc,nacpos)+length(home),raz);
      end else
        result:='';
    end;
  end else if parstype=1 then begin
    if copy(doc,posex(eend,doc,nacpos)+length(eend),1)<>copy(home,1,1) then begin
      raz:=posex(home,doc,nacpos)-posex(eend,doc,nacpos)-length(eend);
      result:=copy(doc,posex(eend,doc,nacpos)+length(eend),raz);
    end else
      result:='';
  end;
  exit;
end;


function URLEncode(const S2: string): string;
var
Idx: Integer;
begin
Result := '';
for Idx := 1 to Length(S2) do
begin
if S2[Idx] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '=', '&', ':', '/', '?', ';', '_'] then
Result := Result + S2[Idx]
else
Result := Result + '%' + IntToHex(Ord(S2[Idx]), 2);
end;
end;


 function ReplaceSub(str, sub1, sub2: string): string;
var
  aPos: Integer;
  rslt: string;
begin
  aPos := Pos(sub1, str);
  rslt := '';
  while (aPos <> 0) do
  begin
    rslt := rslt + Copy(str, 1, aPos - 1) + sub2;
    Delete(str, 1, aPos + Length(sub1) - 1);
    aPos := Pos(sub1, str);
  end;
  Result := rslt + str;
end;

function DwFi(SourceFile, DestFile: string;cookie:string=''): Boolean;
var httpsend: THTTPSend;
begin
  result:=true;
  httpsend:=THTTPSend.Create;
  httpsend.Cookies.Text:=cookie;
  try
    httpsend.HTTPMethod('GET',SourceFile );
  except
    on  E : Exception do
      result:=false;
    end;

  httpsend.document.SaveToFile(DestFile);
  httpsend.Free;
  exit;
end;

procedure Explode(var a: array of string; Border, S: string);
var
  S2: string;
  i: Integer;
begin
  i := 0;
  S2 := S + Border;
  repeat
    //setlength(a, i+1);
    try
      a[i] := Copy(S2, 0, Pos(Border, S2) - 1);
    except
    end;
    Delete(S2, 1, Length(a[i] + Border));
    Inc(i);
  until S2 = '';
end ;

function Send(method,url:string;postParams:string='';cookie:string='';showCookie:boolean=false;proxyType:string='';proxy:string='';proxyUser:string='';proxyPass:string='';files:string='';userAgent:string='';referer:string=''):string;
var Header : TStringList;
       Contents : TStringList;
       httpsend: THTTPSend;
        ss: TStringStream;
        i,err:integer;
        s: String;
        FS: TFileStream;
        rev,bound:string;
        mas,mas2,p,v:array[0..500] of string;
const
      FIELD_MASK = #13#10 + '--%s' + #13#10 +
                  'Content-Disposition: form-data; name="%s"' + #13#10 + #13#10
+
                  '%s';
begin
      randomize;
      Header := TStringList.Create;
      Contents := TStringList.Create;
      ss := TStringStream.Create('');
      httpsend:=THTTPSend.Create;
      HTTPsend.UserAgent:=userAgent;
      if referer<>'' then
        httpsend.Headers.Insert(0,'referererer: '+referer);//referererer
      httpsend.Cookies.Text:=cookie;                //cookies
      if files<>'' then begin
        Bound := IntToHex(Random(100000000), 8) + '_Synapse_boundary';

        s := '--' + Bound + #13#10;
        i:=0;
        if pos('&',files)<>0 then begin
          explode(mas,'&',files);
        end else
          mas[0]:=files;
        while mas[i]<>'' do begin
          explode(mas2,',',mas[i]);

            //s:=CRLF;
            s := s + 'content-disposition: form-data; name="' + mas2[0] +'";';
            s := s + ' filename="' +  ExtractFileName(mas2[1]) +'"' + #13#10;
            s := s + 'Content-Type: '+mas2[2] + #13#10 + #13#10;
            //showmessage(s);
            httpsend.Document.Write(Pointer(s)^, Length(s));
            if mas2[1]<>'' then begin
              FS:=TFileStream.Create(mas2[1], fmOpenRead);
              FS.Position := 0;
              httpsend.Document.CopyFrom(FS, FS.Size);
              FS.Free;
            end;
          inc(i);
        end;
        explode(p,'&',postParams);
        i:=0;
        if pos('&',postParams)<>0 then begin
          explode(p,'&',postParams);
        end else
          p[0]:=postParams;
        while p[i]<>'' do begin
          explode(v,'=',p[i]);
          S:= Format(FIELD_MASK,[Bound, v[0],v[1]]);
          httpsend.Document.Write(Pointer(s)^, Length(s));
          inc(i);
        end;
        s := #13#10 + '--' + Bound + '--' + #13#10;
        httpsend.Document.Write(Pointer(s)^, Length(s));
        httpsend.MimeType := 'multipart/form-data, boundary=' + Bound;
      end else begin
        httpsend.MimeType:='application/x-www-form-urlencoded;';
        if method='POST' then begin
          ss.WriteString(postParams);
          httpsend.Document.LoadFromStream(ss);
        end;
      end;
      httpsend.Protocol := '1.1';
     // httpsend.Sock.OnStatus := OnStatus;
      httpsend.Headers.AddStrings(Header);        //headers
      if proxyTYPE='HTTP' then begin
        httpsend.ProxyHost:=Copy(Proxy,1,Pos(':',Proxy)-1);
        httpsend.ProxyPort:=Copy(Proxy,Pos(':',Proxy)+1,Length(Proxy));
      end else if proxyTYPE='SOCKS 4' then begin
        //HTTPsend.Sock.SocksType:=
        HTTPsend.Sock.SocksResolver:=false;
        HTTPsend.Sock.SocksIP := Copy(Proxy,1,Pos(':',Proxy)-1);
        HTTPsend.Sock.SocksPort := Copy(Proxy,Pos(':',Proxy)+1,Length(Proxy));
        HTTPsend.Sock.SocksUsername := proxyUSER;
        HTTPsend.Sock.SocksPassword := proxyPASS;
        //HTTPsend.Sock.SocksOpen;
      end else if proxyTYPE='SOCKS 5' then begin
        //HTTP.Sock.SocksType := ST_Socks5 ;
        HTTPsend.Sock.SocksResolver:=false;
        HTTPsend.Sock.SocksIP := Copy(Proxy,1,Pos(':',Proxy)-1);
        HTTPsend.Sock.SocksPort := Copy(Proxy,Pos(':',Proxy)+1,Length(Proxy));
        HTTPsend.Sock.SocksUsername := proxyUSER;
        HTTPsend.Sock.SocksPassword := proxyPASS;
        //HTTPsend.Sock.SocksOpen;
      end;
      if method='GET' then begin
        try
          httpsend.HTTPMethod('GET',url );
        except
          //on EidSocketError do
          on  E : Exception do
            result:='exception';
        end;
      end;
      if method='POST' then begin
        httpsend.HTTPMethod('POST',url);
      end;
      Contents.LoadFromStream(httpsend.Document);
      rev := Contents.Text;
      if pos('302',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:=HTTPsend.Headers[FoundLocationStrNum('Location',HTTPsend.Headers)];
      end else    if pos('500',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:='500'+HTTPsend.Headers.Text;
      end else   if pos('404',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:='404';
      end else   if pos('400',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:='400';
      end else  if pos('307',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:=HTTPsend.Headers[FoundLocationStrNum('Location',HTTPsend.Headers)];
      end  else  if pos('301',IntToStr(HTTPsend.ResultCode))<>0 then begin
        result:=HTTPsend.Headers[FoundLocationStrNum('Location',HTTPsend.Headers)];
      end else
        result:=rev;
      if ShowCookie=true  then
        result:=httpsend.Cookies.Text+'@@@'+result;
      httpsend.Free;
      header.Free;
      contents.Free;
      ss.Free;

      exit;
end;

 function FoundLocationStrNum(str:string;Headers: TStringlist): integer;
var
  FoundStrPos, i   : integer;
begin
  Result:= 0;
  for i := 0 to Headers.Count-1 do
  begin
    FoundStrPos := Pos(trim(str), Headers.Strings[i]);
    if FoundStrPos > 0 then
    begin
      Result:= i; 
      exit;
    end;
  end;
end;

end.
 