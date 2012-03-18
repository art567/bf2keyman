unit crypt;

interface

function EncodeBase64(const inStr: string): string;
function DecodeBase64(const CinLine: string): string;
function EncryptData(const AData: WideString; const Key: WideString = ''): WideString;
function DecryptData(const AData: WideString; const Key: WideString = ''): WideString;
function EncryptDataB64(const AData: String; const Key: String = ''): String;
function DecryptDataB64(const AData: String; const Key: String = ''): String;
function EncryptDataHex(const AData: String; const Key: String = ''): String;
function DecryptDataHex(const AData: String; const Key: String = ''): String;
function EncryptDataBF2(const AData: String): String;
function DecryptDataBF2(const AData: String): String;

implementation

uses
  Windows,
  SysUtils;

const
  crypt32                   = 'crypt32.dll';
  CRYPTPROTECT_UI_FORBIDDEN = $01;

type
  DATA_BLOB  = record
    cbData: DWORD;
    pbData: Windows.PBYTE;
  end;
  PDATA_BLOB = ^DATA_BLOB;
  LPLPWSTR  = ^LPWSTR;

 { WideStringToString }

function WideStringToString(const ws: WideString; codePage: Word): AnsiString;
var
  l: integer;
begin
  if ws = '' then
    Result := ''
else
  begin
    l := WideCharToMultiByte(codePage,
      WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
      @ws[1], -1, nil, 0, nil, nil);
    SetLength(Result, l - 1);
    if l > 1 then
      WideCharToMultiByte(codePage,
        WC_COMPOSITECHECK or WC_DISCARDNS or WC_SEPCHARS or WC_DEFAULTCHAR,
        @ws[1], -1, @Result[1], l - 1, nil, nil);
  end;
end;

 { StringToWideString }

function StringToWideString(const s: AnsiString; codePage: Word): WideString;
var
  l: integer;
begin
  if s = '' then
    Result := ''
else
  begin
    l := MultiByteToWideChar(codePage, MB_PRECOMPOSED, PChar(@s[1]), -1, nil,
      0);
    SetLength(Result, l - 1);
    if l > 1 then
      MultiByteToWideChar(CodePage, MB_PRECOMPOSED, PChar(@s[1]),
        -1, PWideChar(@Result[1]), l - 1);
  end;
end;

 { BlobDataToHexStr }
 
function BlobDataToHexStr(P: PByte; I: Integer): string;
var
  HexStr: string;
begin
  HexStr := '';
  while (I > 0) do begin
    Dec(I);
    HexStr := HexStr + IntToHex(P^, 2);
    Inc(P);
  end;
  Result := HexStr;
end;

 { StrToHex }

function StrToHex(source: String): String;
var
  i: Integer;
  c: Char;
  s: string;
begin
  s := '';
  for i:=1 to Length(source) do begin
    c := source[i];
    s := s +  IntToHex(Integer(c), 2) + ' ';
  end;
  result := s;
end;

  { HexToStr }

function HexToStr(source: String): String;
var
  i: integer;
begin
  Result:= '';
  for i := 1 to length (source) div 2 do
    Result:= Result+Char(StrToInt('$'+Copy(source,(i-1)*2+1,2)));
end;

 { Base64 encoding }

function EncodeBase64(const inStr: string): string;

  function Encode_Byte(b: Byte): char;
  const
    Base64Code: string[64] =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  begin
    Result := Base64Code[(b and $3F)+1];
  end;

var
  i: Integer;
begin
  i := 1;
  Result := '';
  while i <= Length(InStr) do
  begin
    Result := Result + Encode_Byte(Byte(inStr[i]) shr 2);
    Result := Result + Encode_Byte((Byte(inStr[i]) shl 4) or (Byte(inStr[i+1]) shr 4));
    if i+1 <= Length(inStr) then
      Result := Result + Encode_Byte((Byte(inStr[i+1]) shl 2) or (Byte(inStr[i+2]) shr 6))
    else
      Result := Result + '=';
    if i+2 <= Length(inStr) then
      Result := Result + Encode_Byte(Byte(inStr[i+2]))
    else
      Result := Result + '=';
    Inc(i, 3);
  end;
end;

 { Base64 decoding }

function DecodeBase64(const CinLine: string): string;
const
  RESULT_ERROR = -2;
var
  inLineIndex: Integer;
  c: Char;
  x: SmallInt;
  c4: Word;
  StoredC4: array[0..3] of SmallInt;
  InLineLength: Integer;
begin
  Result := '';
  inLineIndex := 1;
  c4 := 0;
  InLineLength := Length(CinLine);

  while inLineIndex <= InLineLength do
  begin
    while (inLineIndex <= InLineLength) and (c4 < 4) do
    begin
      c := CinLine[inLineIndex];
      case c of
        '+'     : x := 62;
        '/'     : x := 63;
        '0'..'9': x := Ord(c) - (Ord('0')-52);
        '='     : x := -1;
        'A'..'Z': x := Ord(c) - Ord('A');
        'a'..'z': x := Ord(c) - (Ord('a')-26);
      else
        x := RESULT_ERROR;
      end;
      if x <> RESULT_ERROR then
      begin
        StoredC4[c4] := x;
        Inc(c4);
      end;
      Inc(inLineIndex);
    end;

    if c4 = 4 then
    begin
      c4 := 0;
      Result := Result + Char((StoredC4[0] shl 2) or (StoredC4[1] shr 4));
      if StoredC4[2] = -1 then Exit;
      Result := Result + Char((StoredC4[1] shl 4) or (StoredC4[2] shr 2));
      if StoredC4[3] = -1 then Exit;
      Result := Result + Char((StoredC4[2] shl 6) or (StoredC4[3]));
    end;
  end;
end;

function CryptProtectData(pDataIn: PDATA_BLOB; szDataDescr: LPCWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall; external crypt32 name 'CryptProtectData';

function CryptUnprotectData(pDataIn: PDATA_BLOB; ppszDataDescr: LPLPWSTR;
  pOptionalEntropy: PDATA_BLOB; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDATA_BLOB): BOOL; stdcall; external crypt32 name 'CryptUnprotectData';

function EncryptData(const AData: WideString; const Key: WideString = ''): WideString;
var
  ADataIn:  DATA_BLOB;
  ADataOut: DATA_BLOB;
  AEntropy: DATA_BLOB;
  AStr: String;
begin
  Result          := '';
  ADataIn.cbData  := Length(AData);
  ADataIn.pbData  := PByte(AData);
  ADataOut.cbData := 0;
  ADataOut.pbData := nil;
  if (Key <> '')
  then AStr       := Key
  else AStr       := 'KEY';
  AEntropy.cbData := Length(AStr);
  AEntropy.pbData := PByte(AStr);
  if Win32Check(
     CryptProtectData(@ADataIn,
                      PWideChar(WideString(AStr)),
                      @AEntropy,
                      nil,
                      nil,
                      CRYPTPROTECT_UI_FORBIDDEN,
                      @ADataOut)
    ) then
  try
    SetString(Result, PChar(ADataOut.pbData), ADataOut.cbData);
  finally
    LocalFree(HLOCAL(ADataOut.pbData));
  end;
end;

function DecryptData(const AData: WideString; const Key: WideString = ''): WideString;
var
  ADataIn:  DATA_BLOB;
  ADataOut: DATA_BLOB;
  ADescription: PWideChar;
  AEntropy: DATA_BLOB;
  AStr: String;
begin
  Result          := '';
  ADataIn.cbData  := Length(AData);
  ADataIn.pbData  := PByte(AData);
  ADataOut.cbData := 0;
  ADataOut.pbData := nil;
  if (Key <> '')
  then AStr       := Key
  else AStr       := 'KEY';
  AEntropy.cbData := Length(AStr);
  AEntropy.pbData := PByte(AStr);
  if Win32Check(
     CryptUnprotectData(@ADataIn,
                        @ADescription,
                        @AEntropy,
                        nil,
                        nil,
                        CRYPTPROTECT_UI_FORBIDDEN,
                        @ADataOut)
    ) then
  try
    SetString(Result, PChar(ADataOut.pbData), ADataOut.cbData);
  finally
    LocalFree(HLOCAL(ADataOut.pbData));
    LocalFree(HLOCAL(ADescription));
  end;
end;

function EncryptDataB64(const AData: String; const Key: String): String;
begin
  Result := EncodeBase64(EncryptData(AData, Key));
end;

function DecryptDataB64(const AData: String; const Key: String): String;
begin
  Result := DecryptData(DecodeBase64(AData), Key);
end;

function EncryptDataHex(const AData: String; const Key: String = ''): String;
var
  ADataIn: DATA_BLOB;
  ADataOut: DATA_BLOB;
  AEntropy: DATA_BLOB;
  AStr: String;
begin
  Result          := '';
  ADataIn.cbData  := Length(AData);
  ADataIn.pbData  := PByte(AData);
  ADataOut.cbData := 0;
  ADataOut.pbData := nil;
  if (Key <> '')
  then AStr       := Key
  else AStr       := 'KEY';
  AEntropy.cbData := Length(AStr);
  AEntropy.pbData := PByte(AStr);
  if Win32Check(
     CryptProtectData(@ADataIn,
                      PWideChar(StringToWideString(AStr, CP_ACP)),
                      nil,
                      nil,
                      nil,
                      CRYPTPROTECT_UI_FORBIDDEN,
                      @ADataOut)
    ) then
  try
    Result := BlobDataToHexStr(ADataOut.pbData, ADataOut.cbData);
  finally
    LocalFree(HLOCAL(ADataOut.pbData));
  end;
end;

function DecryptDataHex(const AData: String; const Key: String = ''): String;
var
  ADataStr: String;
  ADataIn:  DATA_BLOB;
  ADataOut: DATA_BLOB;
  ADesc:    PWideChar;
  AEntropy: DATA_BLOB;
  AStr: String;
begin
  Result          := '';
  ADataStr        := HexToStr(AData);
  ADataIn.cbData  := Length(ADataStr);
  ADataIn.pbData  := PByte(ADataStr);
  ADataOut.cbData := 0;
  ADataOut.pbData := nil;
  if (Key <> '')
  then AStr       := Key
  else AStr       := 'KEY';
  ADesc := PWideChar(StringToWideString(AStr, CP_ACP));
  AEntropy.cbData := Length(AStr);
  AEntropy.pbData := PByte(AStr);
  if Win32Check(
     CryptUnprotectData(@ADataIn,
                        @ADesc,
                        nil,
                        nil,
                        nil,
                        CRYPTPROTECT_UI_FORBIDDEN,
                        @ADataOut)
    ) then
  try
    SetString(Result, PChar(ADataOut.pbData), ADataOut.cbData);
  finally
    LocalFree(HLOCAL(ADataOut.pbData));
    LocalFree(HLOCAL(ADesc));
  end;
end;

function EncryptDataBF2(const AData: String): String;
var
  WS: String;
  WK: String;
begin
  WS := AData;
  WK := 'This is the description string.';
  Result := LowerCase(EncryptDataHex(WS, WK));
end;

function DecryptDataBF2(const AData: String): String;
var
  WS: String;
  WK: String;
begin
  WS := AData;
  WK := 'This is the description string.';
  Result := LowerCase(DecryptDataHex(WS, WK));
end;

end.
