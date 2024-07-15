unit main;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  DateUtils,
  Registry,
  Clipbrd,
  Crypt;

{$DEFINE APP_MODE_GUI}
{$IFDEF APP_MODE_GUI}
  {$APPTYPE GUI}
  const
    bGuiMode = True;
{$ELSE}
  {$APPTYPE CONSOLE}
  const
    bGuiMode = False;
{$ENDIF}

type
  TLocStr = record
    Ident: AnsiString;
    Data:  AnsiString;
  end;
  TKeyEdit = class(TCustomEdit)
    constructor Create(AOwner: TComponent); override;
  private
    lNextControl: TWinControl;
    lPrevControl: TWinControl;
    lGroupIndex: Cardinal;
    procedure KEditChange(Sender: TObject);
    procedure KEditKeyPress(Sender: TObject; var Key: Char);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  published
    property NextControl: TWinControl read lNextControl write lNextControl;
    property PrevControl: TWinControl read lPrevControl write lPrevControl;
    property GroupIndex: Cardinal read lGroupIndex write lGroupIndex;
  end;
  TMainForm = class(TForm)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    BF2Key:     String;
    BF2SFKey:   String;
    procedure edt1keyChange(Sender: TObject);
    procedure edt2keyChange(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnRandClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  public
    Image:      TImage;
    Group:      TPanel;
    btnApply:   TButton;
    btnRand:    TButton;
    btnClose:   TButton;
    edt1Key1p:  TKeyEdit;
    edt1Key2p:  TKeyEdit;
    edt1Key3p:  TKeyEdit;
    edt1Key4p:  TKeyEdit;
    edt1Key5p:  TKeyEdit;
    edt2Key1p:  TKeyEdit;
    edt2Key2p:  TKeyEdit;
    edt2Key3p:  TKeyEdit;
    edt2Key4p:  TKeyEdit;
    edt2Key5p:  TKeyEdit;
    lblTitle:   TLabel;
    lblTitleSh: TLabel;
    lblStatic1: TLabel;
    lblStatic2: TLabel;
    lblStatic3: TLabel;
    lblStatic4: TLabel;
    lblStatic5: TLabel;
    lbl1Key12:  TLabel;
    lbl1Key23:  TLabel;
    lbl1Key34:  TLabel;
    lbl1Key45:  TLabel;
    lbl2Key12:  TLabel;
    lbl2Key23:  TLabel;
    lbl2Key34:  TLabel;
    lbl2Key45:  TLabel;
    procedure SetTitle(Title: String);
    function FillBF2Key(Key: String): Byte;
    function FillSFKey(Key: String): Byte;
    function GenKeys: Byte;
    function ChkKeys: Byte;
    function GetKeys: Byte;
    function SetKeys: Byte;
  end;

var
  MainForm: TMainForm;
  IDL: array[0..127] of TLocStr;
  hKernel: THandle;
  c: Integer;
  r: Integer;

const
  c_identhash     = 'x9392';
  c_bfkeysize     = 20; {4 char x 5 parts}
  {c_app_name      = 'Battlefield 2 :: Key Manager';
  c_app_title     = '%s %s';
  c_app_ver       = 'v1.0';
  c_btn_apply     = 'Apply';
  c_btn_rand      = 'Random';
  c_btn_close     = 'Close';
  c_txt_title     = 'Battlefield 2 :: Key Manager';
  c_txt_desc      = 'Hello, i''ll provide you some features to enter'#13#10'your license CD-KEY or key that you bought in Origin/Steam store.'#13#10#13#10'If you don''t have a license key then press ''Random'','#13#10'this allow you playing on non-ranked servers.';
  c_txt_bf2key    = 'Please enter your Battlefield 2 license key below';
  c_txt_bf2sfkey  = 'Please enter your Battlefield 2 Special Forces license key below';
  c_txt_bf2unk    = 'The key state is unknown';
  c_txt_bf2act    = 'This key is already active';
  c_txt_bf2new    = 'You need to press ''Apply'' to actualize this key';
  c_txt_bf2nope   = 'The key you have entered is invalid';}

function HasConsole: Boolean;
function InitConsole: Integer;
function DeinitConsole: Integer;
function Cls: Integer;
function WaitForKey: Integer;
function Title(Text: String = ''): Integer;
function Echo(Text: String = ''): Integer;
function EchoU(Text: String = ''): Integer;
function CmdSwitch(const Switch: string): Boolean;
function CmdParam(const Switch: string): string;
function MsgBox(Text: string; Caption: string = ''; Buttons: integer = 0): integer;
procedure InitLocalization;
function SetBF2Key(RegKey: String = ''; Key: String = ''): Byte;
function SetBF2SFKey(RegKey: String = ''; Key: String = ''): Byte;

implementation

 { Console }

function HasConsole: Boolean;
var
  hStdOut: THandle;
begin
  hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  Result := (hStdOut <> 0) and (hStdOut <> INVALID_HANDLE_VALUE);
end;

function InitConsole: Integer;
var
  bConsole: Boolean;
  AttachConsole: function(dwProcessId: DWORD): Bool; stdcall;
begin
  Result := 0;
  if bGuiMode then
  begin
    // Attach to existing console
    try
      hKernel := LoadLibrary('kernel32.dll');
      if (hKernel <> 0) then
      begin
        @AttachConsole := GetProcAddress(hKernel, 'AttachConsole');
        if Assigned(@AttachConsole) then
        begin
          bConsole := AttachConsole($FFFFFFFF);
          if bConsole then
          begin
            Result := 2;
          end;
        end;
      end;
    except end;
  end else
  begin
    // We already have console
    // SetConsoleTitle( PChar( ChangeFileExt( ExtractFileName( GetModuleName( 0 ) ), '' ) + ' :: Working' ) );
    Result := 1;
  end;
  c := Result;
end;

function DeinitConsole: Integer;
begin
  Result := 0;
  try
    FreeConsole;
    FreeLibrary(hKernel);
  except
    Result := 1;
  end;
end;

function Cls: Integer;
var
  i: Integer;  
  hStdOut: HWND;
  ScreenBufInfo: TConsoleScreenBufferInfo;
  Coord: TCoord;
begin
  Result := 0;
  //if ( not HasConsole ) then
  //begin
  //  Result := 2;
  //  Exit;
  //end;
  if (c > 0) then
  begin
    hStdOut := GetStdHandle(STD_OUTPUT_HANDLE);
    GetConsoleScreenBufferInfo(hStdOut, ScreenBufInfo);
    for i := 1 to ScreenBufInfo.dwSize.Y do
    begin
      WriteLn('');
    end;
    Coord.X := 0;
    Coord.Y := 0;
    SetConsoleCursorPosition(hStdOut, Coord);
  end else
  begin
    Result := 1;
  end;
end;

function WaitForKey: Integer;
begin
  Result := 0;
  //if ( not HasConsole ) then
  //begin
  //  Result := 2;
  //  Exit;
  //end;
  if (c > 0) then
  begin
    ReadLn;
    //Sleep(500);
  end else
  begin
    Result := 1;
  end;
end;

function Title(Text: String = ''): Integer;
begin
  Result := 0;
  //if ( not HasConsole ) then
  //begin
  //  Result := 2;
  //  Exit;
  //end;
  if (c > 0) then
  begin
    SetConsoleTitle( PChar( Text ) );
  end else
  begin
    Result := 1;
  end;
end;

function Echo(Text: String = ''): Integer;
begin
  Result := 0;
  //if ( not HasConsole ) then
  //begin
  //  Result := 2;
  //  Exit;
  //end;
  if (c > 0) then
  begin
    Writeln(Text);
  end else
  begin
    Result := 1;
  end;
end;

function EchoU(Text: String = ''): Integer;
begin
  Result := 0;
  //if ( not HasConsole ) then
  //begin
  //  Result := 2;
  //  Exit;
  //end;
  if (c > 0) then
  begin
    Write(Text);
  end else
  begin
    Result := 1;
  end;
end;

 { Command Line }

function CmdSwitch(const Switch: string): Boolean;
const
  IgnoreCase = true;
  CmdSK = ['-', '\', '/', '+']; // single char defined keys
  CmdDK = '--';                 // double char key definition
var
  i: integer;
  s: string;
begin
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (Copy(s, 1, 2) = CmdDK) then
    begin
      if (IgnoreCase) then
      begin
        if (AnsiCompareText(Copy(s, Length(CmdDK) + 1, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end else
      begin
        if (AnsiCompareStr(Copy(s, Length(CmdDK) + 1, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
    if ((CmdSK = []) or (s[1] in CmdSK)) then
    begin
      if (IgnoreCase) then
      begin
        if (AnsiCompareText(Copy(s, 2, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end else
      begin
        if (AnsiCompareStr(Copy(s, 2, Maxint), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
  Result := False;
  //Result := FindCmdLineSwitch(Switch, keys, True) or
  //  FindCmdLineSwitch(dk1 + Switch, [dk1], True);
end;

function CmdParam(const Switch: string): string;
const
  IgnoreCase = true;
  CmdSK = ['-', '\', '/', '+']; // single char defined keys
  CmdDK = '--';                 // double char key definition
var
  i: integer;
  s: string;
begin
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (Copy(s, 1, 2) = CmdDK) then
    begin
      if (IgnoreCase) then
      begin
        if (AnsiCompareText(Copy(s, Length(CmdDK) + 1, Maxint), Switch) = 0) then
        begin
          if (i < ParamCount) then
          begin
            Result := ParamStr(i + 1);
            Exit;
          end;
        end;
      end else
      begin
        if (AnsiCompareStr(Copy(s, Length(CmdDK) + 1, Maxint), Switch) = 0) then
        begin
          if (i < ParamCount) then
          begin
            Result := ParamStr(i + 1);
            Exit;
          end;
        end;
      end;
    end;
    if ((CmdSK = []) or (s[1] in CmdSK)) then
    begin
      if (IgnoreCase) then
      begin
        if (AnsiCompareText(Copy(s, 2, Maxint), Switch) = 0) then
        begin
          if (i < ParamCount) then
          begin
            Result := ParamStr(i + 1);
            Exit;
          end;
        end;
      end else
      begin
        if (AnsiCompareStr(Copy(s, 2, Maxint), Switch) = 0) then
        begin
          if (i < ParamCount) then
          begin
            Result := ParamStr(i + 1);
            Exit;
          end;
        end;
      end;
    end;
  end;
  Result := EmptyStr;
end;

 { Simple MsgBox function }

function MsgBox(Text: string; Caption: string = ''; Buttons: integer = 0): integer;
begin
  if (Caption = '') then
  begin
    Caption := Application.Title;
  end;
  Result := MessageBox(Application.Handle, PAnsiChar(Text), PAnsiChar(Caption), Buttons);
end;

 { Localization }

function L_GET(Ident: String): String;
var
  i: Integer;
  id: String;
begin
  i := 0;
  Result := Ident;
  id := LowerCase(Ident);
  while (i < 128) do
  begin
    if (LowerCase(IDL[i].Ident) = id) then
    begin
      Result := IDL[i].Data;
    end;
    Inc(i);
  end;
end;

function L_SET(Ident, Data: String): Byte;
var
  i: Integer;
  id: String;
begin
  i := 0;
  Result := 0;
  id := LowerCase(Ident);
  while (i < 128) do
  begin
    if (IDL[i].Ident = '') or (LowerCase(IDL[i].Ident) = id) then
    begin
      IDL[i].Ident := id;
      IDL[i].Data  := Data;
      Exit;
    end;
    Inc(i);
  end;
  Result := 1;
end;

function GetLanguageID: Cardinal;
begin
  Result := GetUserDefaultLangID;
end;

function GetLanguageName: String;
var
  ID: LangID;
  Language: array [0..255] of Char;
begin
  ID := GetUserDefaultLangID;
  VerLanguageName(ID, Language, SizeOf(Language));
  Result:=String(Language);
end;

function GetResStr(LangID: Cardinal; StringIdx: Cardinal): String;
var
  UID: Cardinal;
  Buf: array [0..1024] of Char;
begin
  Result := '';
  try
    UID := ((LangID-1)*16) + StringIdx;
    LoadString(HInstance, UID, Buf, SizeOf(Buf));
    Result := String(Buf);
  except end;
end;

procedure LocalizationFromResource(ID: Cardinal);
begin
  if (FindResource(hInstance, Pointer(ID), RT_STRING) <> 0) then
  begin
    L_SET('app.name',      GetResStr(ID, 0));
    L_SET('app.title',     GetResStr(ID, 1));
    L_SET('app.ver',       GetResStr(ID, 2));
    L_SET('btn.apply',     GetResStr(ID, 3));
    L_SET('btn.rand',      GetResStr(ID, 4));
    L_SET('btn.close',     GetResStr(ID, 5));
    L_SET('txt.title',     GetResStr(ID, 6));
    L_SET('txt.desc',      GetResStr(ID, 7));
    L_SET('txt.bf2key',    GetResStr(ID, 8));
    L_SET('txt.bf2sfkey',  GetResStr(ID, 9));
    L_SET('txt.bf2unk',    GetResStr(ID, 10));
    L_SET('txt.bf2act',    GetResStr(ID, 11));
    L_SET('txt.bf2new',    GetResStr(ID, 12));
    L_SET('txt.bf2inv',    GetResStr(ID, 13));
    L_SET('txt.bf2nope',   GetResStr(ID, 14));
  end;
end;

procedure InitLocalization;
const
  ID = 1033;
begin
  // Default localization
  L_SET('app.name',      GetResStr(ID, 0));
  L_SET('app.title',     GetResStr(ID, 1));
  L_SET('app.ver',       GetResStr(ID, 2));
  L_SET('btn.apply',     GetResStr(ID, 3));
  L_SET('btn.rand',      GetResStr(ID, 4));
  L_SET('btn.close',     GetResStr(ID, 5));
  L_SET('txt.title',     GetResStr(ID, 6));
  L_SET('txt.desc',      GetResStr(ID, 7));
  L_SET('txt.bf2key',    GetResStr(ID, 8));
  L_SET('txt.bf2sfkey',  GetResStr(ID, 9));
  L_SET('txt.bf2unk',    GetResStr(ID, 10));
  L_SET('txt.bf2act',    GetResStr(ID, 11));
  L_SET('txt.bf2new',    GetResStr(ID, 12));
  L_SET('txt.bf2inv',    GetResStr(ID, 13));
  L_SET('txt.bf2nope',   GetResStr(ID, 14));
  // Get Localized strings from resources
  LocalizationFromResource( GetLanguageID );
end;

 { Registry Calls functions }

function GetRegistryData(RootKey: HKEY; Key, Value: string): variant;
var
  Reg: TRegistry;
  RegDataType: TRegDataType;
  DataSize, Len: integer;
  s: string;
  label cantread;
begin
  Reg := nil;
  try
    Reg := TRegistry.Create(KEY_QUERY_VALUE);
    Reg.RootKey := RootKey;
    if Reg.OpenKeyReadOnly(Key) then begin
      try
        RegDataType := Reg.GetDataType(Value);
        if (RegDataType = rdString) or
           (RegDataType = rdExpandString) then
          Result := Reg.ReadString(Value)
        else if RegDataType = rdInteger then
          Result := Reg.ReadInteger(Value)
        else if RegDataType = rdBinary then begin
          DataSize := Reg.GetDataSize(Value);
          if DataSize = -1 then goto cantread;
          SetLength(s, DataSize);
          Len := Reg.ReadBinaryData(Value, PChar(s)^, DataSize);
          if Len <> DataSize then goto cantread;
          Result := s;
        end else
      cantread:
        raise Exception.Create(SysErrorMessage(ERROR_CANTREAD));
      except
        s := ''; // Deallocates memory if allocated
        Reg.CloseKey;
        raise;
      end;
      Reg.CloseKey;
    end else
      raise Exception.Create(SysErrorMessage(GetLastError));
  except
    Reg.Free;
    raise;
  end;
  Reg.Free;
end;

procedure SetRegistryData(RootKey: HKEY; Key, Value: string;
  RegDataType: TRegDataType; Data: variant);
var
  Reg: TRegistry;
  s: string;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := RootKey;
    if Reg.OpenKey(Key, True) then begin
      try
        if RegDataType = rdUnknown then
          RegDataType := Reg.GetDataType(Value);
        if RegDataType = rdString then
          Reg.WriteString(Value, Data)
        else if RegDataType = rdExpandString then
          Reg.WriteExpandString(Value, Data)
        else if RegDataType = rdInteger then
          Reg.WriteInteger(Value, Data)
        else if RegDataType = rdBinary then begin
          s := Data;
          Reg.WriteBinaryData(Value, PChar(s)^, Length(s));
        end else
          raise Exception.Create(SysErrorMessage(ERROR_CANTWRITE));
      except
        Reg.CloseKey;
        raise;
      end;
      Reg.CloseKey;
    end else
      raise Exception.Create(SysErrorMessage(GetLastError));
  finally
    Reg.Free;
  end;
end;

 { Better font antialising }
 
procedure SetFontSmoothing(AFont: TFont);
var
  tagLOGFONT: TLogFont;
begin
  GetObject(
    AFont.Handle,
    SizeOf(TLogFont),
    @tagLOGFONT);
  tagLOGFONT.lfQuality  := ANTIALIASED_QUALITY;
  AFont.Handle := CreateFontIndirect(tagLOGFONT);
end;

 { Key from Random + Timestamp }

function BuildRandomKey(Size: Integer = c_bfkeysize): String;
const
  Chars = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
var
  i, n: integer;
begin
  Randomize;
  Result := '';
  for i := 1 to Size do begin
    n := Random(Length(Chars)) + 1;
    Result := Result + Chars[n];
  end;
end;

function BuildPseudoRandomKey(Size: Integer = c_bfkeysize): String;
var
  Unix: Integer;
  Rand: Int64;
  Hash: String;
begin
  Randomize;
  Hash := '';
  while (Length(Hash) <= Size) do
  begin
    Unix := DateTimeToUnix(Date + Time);
    Rand := Random(Unix) + Unix;
    Hash := Hash + EncodeBase64(IntToStr(Rand) + EncodeBase64(IntToStr(Rand)));
    Hash := StringReplace(Hash, '+', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '-', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '/', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '=', '', [rfReplaceAll, rfIgnoreCase]);
  end;
  Result := Copy(Hash, 1, Size);
end;

 { Battlefield 2 Decryption }

function GetBF2Key(RegKey: String = ''): String;
var
  s: String;
begin
  Result := '';
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc';
  end;
  try
    s := GetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '');
    s := StringReplace(s, c_identhash, '', [rfReplaceAll, rfIgnoreCase]);
    s := DecryptDataBF2(s);
    Result := UpperCase(s);
  except
  end;
end;

function GetBF2SFKey(RegKey: String = ''): String;
var
  s: String;
begin
  Result := '';
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc';
  end;
  try
    s := GetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '');
    s := StringReplace(s, c_identhash, '', [rfReplaceAll, rfIgnoreCase]);
    s := DecryptDataBF2(s);
    Result := UpperCase(s);
  except
  end;
end;

 { Battlefield 2 Encryption }

function SetBF2Key(RegKey: String = ''; Key: String = ''): Byte;
var
  Hash: String;
begin
  Result := 0;
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc';
  end;
  if (Key = '') then
  begin
    Key := BuildRandomKey;
  end;
  try
    Hash := c_identhash + EncryptDataBF2(Key);
    SetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '', rdString, Hash);
  except
    Result := 1;
  end;
end;

function SetBF2SFKey(RegKey: String = ''; Key: String = ''): Byte;
var
  Hash: String;
begin
  Result := 0;
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc';
  end;
  if (Key = '') then
  begin
    Key := BuildRandomKey;
  end;
  try
    Hash := c_identhash + EncryptDataBF2(Key);
    SetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '', rdString, Hash);
  except
    Result := 1;
  end;
end;

 { TKeyEdit Class }

constructor TKeyEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.OnChange := KEditChange;
  Self.OnKeyPress := KEditKeyPress;
  Self.AutoSize := False;
  Self.CharCase := ecUpperCase;
  Self.Font.Name := 'Tahoma';
  Self.Font.Style := [fsBold];
  Self.Font.Color := clWindowText;
  Self.Font.Size := 10;
  Self.Height := 23;
  Self.MaxLength := 4;
  Self.NextControl := nil;
  Self.Width := 60;
end;

procedure TKeyEdit.CreateParams(var Params: TCreateParams);
const
  Alignments: array[TAlignment] of Longint = (ES_LEFT, ES_RIGHT, ES_CENTER);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or ES_MULTILINE or ES_CENTER;
end;

procedure TKeyEdit.KEditChange(Sender: TObject);
begin
  if (Length(Self.Caption) >= Self.MaxLength) then
  begin
    Self.Color := $00f6fff4;
  end else
  begin
    Self.Color := $00f4f8ff;
  end;
end;

procedure TKeyEdit.KEditKeyPress(Sender: TObject; var Key: Char);
var
  S: String;
  K: String;
  i: Integer;
begin
  if not (Key in [#1, #3, #8, #22, #24, '0'..'9', 'A'..'z']) then
  begin
    // MsgBox('Key: 0x'+IntToHex(Ord(Key), 2));
    Key := #0;
    Exit;
  end else
  begin
    // Handling Ctrl+A hit
    if (Key = #1) then
    begin
      if (Length(Self.Caption) > 0) then
      begin
        try
          TEdit(Self).SelectAll;
          Key := #0;
        except end;
      end;
      Exit;
    end;
    // Handling Ctrl+C hit
    if (Key = #3) then
    begin
      Clipboard.SetTextBuf(PChar(Self.Text));
      Exit;
    end;
    // Handling Ctrl+V hit
    if (Key = #22) then
    begin
      // We will call members from MainForm.
      // This will check form for existence.
      if (MainForm <> nil) then
      begin
        // If complete key persist in clipboard
        if (Length(Clipboard.AsText) >= 20) then
        begin
          // Assign empty target key string
          K := EmptyStr;
          // Copy that string from clipboard
          S := Clipboard.AsText;
          // Remove dashes if present
          S := StringReplace(S, '-', '', [rfReplaceAll, rfIgnoreCase]);
          // Removed unallowed chars
          for i:=1 to Length(S) do
          begin
            if S[i] in ['0'..'9', 'A'..'z'] then
            begin
              K := K + S[i];
            end;
          end;
          // Assign key to appropriate group
          case Self.GroupIndex of
            1: // Battlefield 2 key fields group
            begin
              with MainForm do
              begin
                edt1Key1p.Text := Copy(S, 1, 4);
                edt1Key2p.Text := Copy(S, 5, 4);
                edt1Key3p.Text := Copy(S, 9, 4);
                edt1Key4p.Text := Copy(S, 13, 4);
                edt1Key5p.Text := Copy(S, 17, 4);
              end;
            end;
            2: // BF2: Special Forces key fields group
            begin
              with MainForm do
              begin
                edt2Key1p.Text := Copy(S, 1, 4);
                edt2Key2p.Text := Copy(S, 5, 4);
                edt2Key3p.Text := Copy(S, 9, 4);
                edt2Key4p.Text := Copy(S, 13, 4);
                edt2Key5p.Text := Copy(S, 17, 4);
              end;
            end;
          end;
        end;
      end;
      Exit;
    end;
    // Handling Ctrl+X hit
    if (Key = #24) then
    begin

      Exit;
    end;
    // Handling backspace key hit
    if (Key = #8) then
    begin
      // Move selection cursor if
      if (Self.SelStart <= 0) then
      begin
        if (PrevControl <> nil) then
        begin
          PrevControl.SetFocus;
          try
            TEdit(PrevControl).SelStart := Self.MaxLength;
          except end;
        end;
      end;
      // Move selection cursor if field is empty
      if (Length(Self.Caption) <= 0) then
      begin
        if (PrevControl <> nil) then
        begin
          PrevControl.SetFocus;
          try
            TEdit(PrevControl).SelStart := Self.MaxLength;
          except end;
        end;
      end;
      Exit;
    end;
  end;
  // If field was completely filled
  if (Length(Self.Caption)+1 = Self.MaxLength) then
  begin
    if (NextControl <> nil) then
    begin
      NextControl.SetFocus;
    end;
  end;
end;

 { MainForm Class }

constructor TMainForm.Create(AOwner: TComponent);
const
  ek1t = 160;
  ek2t = 250;
  ekdw = 17;
  eklw = 11;
  eklm = 5;
var
  i: Integer;
  dpi: Double;
  mc: TMonitor;
begin
  { Creating form }
  inherited CreateNew(nil, 0);
  SetTitle( Format(L_GET('app.title')+#32+#169+#32+#84+#101+#109+#97+#53+#54+#55, [L_GET('app.name'), L_GET('app.ver')]) );
  mc := Screen.MonitorFromPoint(Mouse.CursorPos);
  Self.BorderStyle := bsDialog;
  Self.BorderIcons := [];
  Self.Position := poDesigned;
  Self.DefaultMonitor := dmDesktop;
  { Get DPI value }
  dpi := Self.PixelsPerInch / 96;
  { Create window }
  Self.Width := 645;
  Self.Height := 391;
  Self.Left := mc.Left + ((mc.Width - Self.Width) div 2);
  Self.Top := mc.Top + ((mc.Height - Self.Height) div 2);
  { Fix incorrect language }
  if (GetLanguageID = 1049) then
  begin // Russian
    Self.Font.Charset := RUSSIAN_CHARSET;
  end;  // Another else ?
  { Creating image bar }
  Image := TImage.Create(Self);
  with Image do
  begin
    Parent := Self;
    Left := 11;
    Top := 11;
    Height := 335;
    Width := 219;
    try
      Canvas.Brush.Color := clWhite;
      Canvas.FillRect(Rect(11, 11, 335, 219));
      Picture.Bitmap.LoadFromResourceName(hInstance, 'BG');
    except end;
    Canvas.Brush.Color := clBlack;
    Canvas.FrameRect( Canvas.ClipRect );
  end;
  { Creating group bar }
  Group := TPanel.Create(Self);
  with Group do
  begin
    BevelInner := bvRaised;
    BevelOuter := bvLowered;
    Parent := Self;
    Left := 239;
    Top := 11;
    Height := 308;
    Width := 390;
  end;
  { Creating static text }
  lblTitleSh := TLabel.Create(Group);
  with lblTitleSh do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 1;
    Top := 11;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clGray;
    //Font.Name := 'Comic Sans MS';
    Font.Name := 'Segoe Print';
    Font.Size := 11;
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.title');
  end;
  lblTitle := TLabel.Create(Group);
  with lblTitle do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 10;
    Height := 23;
    Width := Parent.Width;
    Font.Color := $000202B9;
    //Font.Name := 'Comic Sans MS';
    Font.Name := 'Segoe Print';
    Font.Size := 11;
    Font.Style := [fsBold, fsUnderline];
    Transparent := True;
    Caption := L_GET('txt.title');
  end;
  lblStatic1 := TLabel.Create(Group);
  with lblStatic1 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 20;
    Top := 40;
    Height := 83;
    Width := Parent.Width-40;
    Font.Color := clGray;
    Font.Name  := 'Tahoma';
    Font.Style := [fsItalic];
    WordWrap := True;
    Transparent := True;
    Caption := L_GET('txt.desc');
  end;
  lblStatic2 := TLabel.Create(Group);
  with lblStatic2 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 138;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.bf2key');
  end;
  lblStatic3 := TLabel.Create(Group);
  with lblStatic3 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 190;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    Transparent := True;
    Caption := L_GET('txt.bf2stat');
  end;
  lblStatic4 := TLabel.Create(Group);
  with lblStatic4 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 228;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.bf2sfkey');
  end;
  lblStatic5 := TLabel.Create(Group);
  with lblStatic5 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 280;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    Transparent := True;
    Caption := L_GET('txt.bf2unk');
  end;
  { Creating 'apply' button }
  btnApply := TButton.Create(Self);
  with btnApply do
  begin
    Parent := Self;
    Caption := L_GET('btn.apply');
    Left := 324;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnApplyClick;
  end;
  { Creating 'random' button }
  btnRand := TButton.Create(Self);
  with btnRand do
  begin
    Parent := Self;
    Caption := L_GET('btn.rand');
    Left := 410;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnRandClick;
  end;
  { Creating 'close' button }
  btnClose := TButton.Create(Self);
  with btnClose do
  begin
    Parent := Self;
    Caption := L_GET('btn.close');
    Left := 496;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnCloseClick;
  end;
  { Creating key fields }
  edt1Key1p := TKeyEdit.Create(Group);
  edt1Key1p.Parent := Group;
  edt1Key1p.GroupIndex := 1;
  edt1Key1p.Left := eklw;
  edt1Key1p.Top := ek1t;
  edt1Key1p.OnChange := edt1keyChange;
  edt1Key2p := TKeyEdit.Create(Group);
  edt1Key2p.Parent := Group;
  edt1Key2p.GroupIndex := 1;
  edt1Key2p.Left := edt1Key1p.Left+edt1Key1p.Width+ekdw;
  edt1Key2p.Top := ek1t;
  edt1Key2p.OnChange := edt1keyChange;
  edt1Key3p := TKeyEdit.Create(Group);
  edt1Key3p.Parent := Group;
  edt1Key3p.GroupIndex := 1;
  edt1Key3p.Left := edt1Key2p.Left+edt1Key2p.Width+ekdw;
  edt1Key3p.Top := ek1t;
  edt1Key3p.OnChange := edt1keyChange;
  edt1Key4p := TKeyEdit.Create(Group);
  edt1Key4p.Parent := Group;
  edt1Key4p.GroupIndex := 1;
  edt1Key4p.Left := edt1Key3p.Left+edt1Key3p.Width+ekdw;
  edt1Key4p.Top := ek1t;
  edt1Key4p.OnChange := edt1keyChange;
  edt1Key5p := TKeyEdit.Create(Group);
  edt1Key5p.Parent := Group;
  edt1Key5p.GroupIndex := 1;
  edt1Key5p.Left := edt1Key4p.Left+edt1Key4p.Width+ekdw;
  edt1Key5p.Top := ek1t;
  edt1Key5p.OnChange := edt1keyChange;
  edt2Key1p := TKeyEdit.Create(Group);
  edt2Key1p.Parent := Group;
  edt2Key1p.GroupIndex := 2;
  edt2Key1p.Left := eklw;
  edt2Key1p.Top := ek2t;
  edt2Key1p.OnChange := edt2keyChange;
  edt2Key2p := TKeyEdit.Create(Group);
  edt2Key2p.Parent := Group;
  edt2Key2p.GroupIndex := 2;
  edt2Key2p.Left := edt2Key1p.Left+edt2Key1p.Width+ekdw;
  edt2Key2p.Top := ek2t;
  edt2Key2p.OnChange := edt2keyChange;
  edt2Key3p := TKeyEdit.Create(Group);
  edt2Key3p.Parent := Group;
  edt2Key3p.GroupIndex := 2;
  edt2Key3p.Left := edt2Key2p.Left+edt2Key2p.Width+ekdw;
  edt2Key3p.Top := ek2t;
  edt2Key3p.OnChange := edt2keyChange;
  edt2Key4p := TKeyEdit.Create(Group);
  edt2Key4p.Parent := Group;
  edt2Key4p.GroupIndex := 2;
  edt2Key4p.Left := edt2Key3p.Left+edt2Key3p.Width+ekdw;;
  edt2Key4p.Top := ek2t;
  edt2Key4p.OnChange := edt2keyChange;
  edt2Key5p := TKeyEdit.Create(Group);
  edt2Key5p.Parent := Group;
  edt2Key5p.GroupIndex := 2;
  edt2Key5p.Left := edt2Key4p.Left+edt2Key4p.Width+ekdw;;
  edt2Key5p.Top := ek2t;
  edt2Key5p.OnChange := edt2keyChange;
  { Linking Next Edits }
  edt1Key1p.NextControl := edt1Key2p;
  edt1Key2p.NextControl := edt1Key3p;
  edt1Key3p.NextControl := edt1Key4p;
  edt1Key4p.NextControl := edt1Key5p;
  edt1Key5p.NextControl := edt2Key1p;
  edt2Key1p.NextControl := edt2Key2p;
  edt2Key2p.NextControl := edt2Key3p;
  edt2Key3p.NextControl := edt2Key4p;
  edt2Key4p.NextControl := edt2Key5p;
  { Linking Prev Edits }
  edt1Key2p.PrevControl := edt1Key1p;
  edt1Key3p.PrevControl := edt1Key2p;
  edt1Key4p.PrevControl := edt1Key3p;
  edt1Key5p.PrevControl := edt1Key4p;
  edt2Key2p.PrevControl := edt2Key1p;
  edt2Key3p.PrevControl := edt2Key2p;
  edt2Key4p.PrevControl := edt2Key3p;
  edt2Key5p.PrevControl := edt2Key4p;
  { Creating - caps }
  lbl1Key12 := TLabel.Create(Self);
  with lbl1Key12 do
  begin
    Parent := Group;
    Top := edt1Key1p.Top;
    Left := edt1Key1p.Left + edt1Key1p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key23 := TLabel.Create(Self);
  with lbl1Key23 do
  begin
    Parent := Group;
    Top := edt1Key2p.Top;
    Left := edt1Key2p.Left + edt1Key2p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key34 := TLabel.Create(Self);
  with lbl1Key34 do
  begin
    Parent := Group;
    Top := edt1Key3p.Top;
    Left := edt1Key3p.Left + edt1Key3p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key45 := TLabel.Create(Self);
  with lbl1Key45 do
  begin
    Parent := Group;
    Top := edt1Key4p.Top;
    Left := edt1Key4p.Left + edt1Key4p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key12 := TLabel.Create(Self);
  with lbl2Key12 do
  begin
    Parent := Group;
    Top := edt2Key1p.Top;
    Left := edt2Key1p.Left + edt2Key1p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key23 := TLabel.Create(Self);
  with lbl2Key23 do
  begin
    Parent := Group;
    Top := edt2Key2p.Top;
    Left := edt2Key2p.Left + edt2Key2p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key34 := TLabel.Create(Self);
  with lbl2Key34 do
  begin
    Parent := Group;
    Top := edt2Key3p.Top;
    Left := edt2Key3p.Left + edt2Key3p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key45 := TLabel.Create(Self);
  with lbl2Key45 do
  begin
    Parent := Group;
    Top := edt2Key4p.Top;
    Left := edt2Key4p.Left + edt2Key4p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  if (dpi > 1.0) then
  begin
    // DPI is different
    if (dpi > 1.00) and (dpi <= 1.25) then
    begin
      with Self do
      begin
        ClientWidth  := Round(ClientWidth  * 1.20);
        ClientHeight := Round(ClientHeight * 1.15);
      end;
      with Self.Image do
      begin
        Width  := Round(Width  * 1.155);
        Height := Round(Height * 1.155);
        Stretch := True;
      end;
      with Self.Group do
      begin
        Left := Image.Left + Image.Width + 12;
        Width := Self.ClientWidth - Left - 12;
        Height := Round(Height * 1.10);
      end;
      with Self.btnRand do
      begin
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.50);
        Left := Group.Left + Round(Group.Width * 0.5) - Round(Width * 0.5);
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.btnApply do
      begin
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.50);
        Left := btnRand.Left - btnRand.Width - 12;
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.btnClose do
      begin
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.50);
        Left := btnRand.Left + btnRand.Width + 12;
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.lblTitle do
      begin
        Top := 12;
        Left := 12;
        Width := Group.Width - 12 - 12;
		Height := Round(Height * 1.10);
		// Font.Style := [fsUnderline];
      end;
      with Self.lblTitleSh do
      begin
        Top := 13;
        Left := 13;
        Width := Group.Width - 12 - 12;
		Height := Round(Height * 1.10);
		// Font.Style := [fsUnderline];
      end;
      with Self.lblStatic1 do
      begin
        Top := lblTitle.Top + lblTitle.Height + 20;
        Left := 12;
        Width := Group.Width - 12 - 12;
      end;
      with Self.lblStatic2 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := lblStatic1.Top + lblStatic1.Height + 20;
      end;
      with Self.edt1Key1p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := 15;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key12.Top := Top;
        lbl1Key12.Left := Left + Width + 4;
      end;
      with Self.edt1Key2p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key23.Top := Top;
        lbl1Key23.Left := Left + Width + 4;
      end;
      with Self.edt1Key3p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key34.Top := Top;
        lbl1Key34.Left := Left + Width + 4;
      end;
      with Self.edt1Key4p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key45.Top := Top;
        lbl1Key45.Left := Left + Width + 4;
      end;
      with Self.edt1Key5p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
      end;
      with Self.lblStatic3 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := edt1Key3p.Top + edt1Key3p.Height + 2;
      end;
      with Self.lblStatic4 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := lblStatic3.Top + lblStatic3.Height + 16;
      end;
      with Self.edt2Key1p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := 15;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key12.Top := Top;
        lbl2Key12.Left := Left + Width + 4;
      end;
      with Self.edt2Key2p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key23.Top := Top;
        lbl2Key23.Left := Left + Width + 4;
      end;
      with Self.edt2Key3p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key34.Top := Top;
        lbl2Key34.Left := Left + Width + 4;
      end;
      with Self.edt2Key4p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key45.Top := Top;
        lbl2Key45.Left := Left + Width + 4;
      end;
      with Self.edt2Key5p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 3;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
      end;
      with Self.lblStatic5 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := edt2Key3p.Top + edt2Key3p.Height + 2;
      end;
    end;
    if (dpi > 1.25) and (dpi <= 1.50) then
    begin
      with Self do
      begin
        ClientWidth  := Round(ClientWidth  * 1.25);
        ClientHeight := Round(ClientHeight * 1.15);
      end;
      with Self.Image do
      begin
        Width  := Round(Width  * 1.165);
        Height := Round(Height * 1.165);
        Stretch := True;
      end;
      with Self.Group do
      begin
        Left := Image.Left + Image.Width + 12;
        Width := Self.ClientWidth - Left - 12;
        Height := Round(Height * 1.10);
      end;
      with Self.btnRand do
      begin
        Width := Round(Width * 1.40);
        Height := Round(Height * 1.60);
        Left := Group.Left + Round(Group.Width * 0.5) - Round(Width * 0.5);
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.btnApply do
      begin
        Width := Round(Width * 1.40);
        Height := Round(Height * 1.60);
        Left := btnRand.Left - btnRand.Width - 12;
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.btnClose do
      begin
        Width := Round(Width * 1.40);
        Height := Round(Height * 1.60);
        Left := btnRand.Left + btnRand.Width + 12;
        Top := Group.Top + Group.Height + 10;
      end;
      with Self.lblTitle do
      begin
        Top := 12;
        Left := 12;
        Width := Group.Width - 12 - 12;
        Height := Round(Height * 1.20);
        Font.Size := 9;
      end;
      with Self.lblTitleSh do
      begin
        Top := 13;
        Left := 13;
        Width := Group.Width - 12 - 12;
        Height := Round(Height * 1.20);
        Font.Size := 9;
      end;
      with Self.lblStatic1 do
      begin
        Top := lblTitle.Top + lblTitle.Height + 20;
        Left := 12;
        Width := Group.Width - 12 - 12;
        Font.Size := 6;
      end;
      with Self.lblStatic2 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := lblStatic1.Top + lblStatic1.Height + 20;
        Font.Size := 6;
      end;
      with Self.edt1Key1p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := 15;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key12.Top := Top;
        lbl1Key12.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt1Key2p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key23.Top := Top;
        lbl1Key23.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt1Key3p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key34.Top := Top;
        lbl1Key34.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt1Key4p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl1Key45.Top := Top;
        lbl1Key45.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt1Key5p do
      begin
        Top := lblStatic2.Top + lblStatic2.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        Font.Size := 9;
      end;
      with Self.lblStatic3 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := edt1Key3p.Top + edt1Key3p.Height + 2;
        Font.Size := 6;
      end;
      with Self.lblStatic4 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := lblStatic3.Top + lblStatic3.Height + 16;
        Font.Size := 6;
      end;
      with Self.edt2Key1p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := 15;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key12.Top := Top;
        lbl2Key12.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt2Key2p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key23.Top := Top;
        lbl2Key23.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt2Key3p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key34.Top := Top;
        lbl2Key34.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt2Key4p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        lbl2Key45.Top := Top;
        lbl2Key45.Left := Left + Width + 7;
        Font.Size := 9;
      end;
      with Self.edt2Key5p do
      begin
        Top := lblStatic4.Top + lblStatic4.Height + 2;
        Left := lPrevControl.Left + lPrevControl.Width + 12 + 9;
        Width := Round(Width * 1.30);
        Height := Round(Height * 1.30);
        Font.Size := 9;
      end;
      with Self.lblStatic5 do
      begin
        Left := 12;
        Width := Group.Width - 12 - 12;
        Top := edt2Key3p.Top + edt2Key3p.Height + 2;
        Font.Size := 6;
      end;
    end;
    if (dpi > 1.50) and (dpi <= 1.75) then
    begin
      MsgBox( 'Sorry. Your DPI is not supported yet!', '', MB_ICONERROR);
      Halt(201);
    end;
    if (dpi > 1.75) and (dpi <= 2.00) then
    begin
      MsgBox( 'Sorry. Your DPI is not supported yet!', '', MB_ICONERROR);
      Halt(201);
    end;
    if (dpi > 2.00) then
    begin
      MsgBox( 'Sorry. Your DPI is not supported yet!', '', MB_ICONERROR);
      Halt(201);
    end;
  end else
  begin
    // DPI is standard
    // nothing to do
  end;
  { Fix ugly fonts }
  {for i := 0 to ComponentCount-1 do
  begin
    if Components[i] is TLabel
    then SetFontSmoothing(TLabel(Components[i]).Font);
    if Components[i] is TButton
    then SetFontSmoothing(TButton(Components[i]).Font);
    if Components[i] is TKeyEdit
    then SetFontSmoothing(TKeyEdit(Components[i]).Font);
  end;}
  { Get Keys }
  GetKeys;
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.SetTitle(Title: String);
begin
  Application.Title := Title;
  Self.Caption := Title;
end;

function TMainForm.GenKeys: Byte;
var
  Key: String;
begin
  Result := 0;
  try
    Key := UpperCase(BuildRandomKey);
    edt1Key1p.Caption := Copy(Key, 1, 4);
    edt1Key2p.Caption := Copy(Key, 5, 4);
    edt1Key3p.Caption := Copy(Key, 9, 4);
    edt1Key4p.Caption := Copy(Key, 13, 4);
    edt1Key5p.Caption := Copy(Key, 17, 4);
  except
    Result := 1;
  end;
  // Get BF2SF
  try
    Key := UpperCase(BuildRandomKey);
    edt2Key1p.Caption := Copy(Key, 1, 4);
    edt2Key2p.Caption := Copy(Key, 5, 4);
    edt2Key3p.Caption := Copy(Key, 9, 4);
    edt2Key4p.Caption := Copy(Key, 13, 4);
    edt2Key5p.Caption := Copy(Key, 17, 4);
  except
    Result := 2;
  end;
end;

function TMainForm.ChkKeys: Byte;
var
  ChKey: String;
begin
  Result := 0;
  try
    ChKey := '';
    ChKey := ChKey + edt1Key1p.Caption;
    ChKey := ChKey + edt1Key2p.Caption;
    ChKey := ChKey + edt1Key3p.Caption;
    ChKey := ChKey + edt1Key4p.Caption;
    ChKey := ChKey + edt1Key5p.Caption;
    if (Length(ChKey) = c_bfkeysize) then
    begin
      if (ChKey = Self.BF2Key) then
      begin
        lblStatic3.Font.Color := clLime;
        lblStatic3.Caption := L_GET('txt.bf2act');
      end else
      begin
        lblStatic3.Font.Color := clBlue;
        lblStatic3.Caption := L_GET('txt.bf2new');
      end;
    end else
    begin
      if (Length(ChKey) < 1) then
      begin
        lblStatic3.Font.Color := clDkGray;
        lblStatic3.Caption := L_GET('txt.bf2nope');
        Result := Result + 1;
      end else
      begin
        lblStatic3.Font.Color := clRed;
        lblStatic3.Caption := L_GET('txt.bf2inv');
        Result := Result + 1;
      end;
    end;
  except
    Result := Result + 1;
  end;
  try
    ChKey := '';
    ChKey := ChKey + edt2Key1p.Caption;
    ChKey := ChKey + edt2Key2p.Caption;
    ChKey := ChKey + edt2Key3p.Caption;
    ChKey := ChKey + edt2Key4p.Caption;
    ChKey := ChKey + edt2Key5p.Caption;
    if (Length(ChKey) = c_bfkeysize) then
    begin
      if (ChKey = Self.BF2SFKey) then
      begin
        lblStatic5.Font.Color := clLime;
        lblStatic5.Caption := L_GET('txt.bf2act');
      end else
      begin
        lblStatic5.Font.Color := clBlue;
        lblStatic5.Caption := L_GET('txt.bf2new');
      end;
    end else
    begin
      if (Length(ChKey) < 1) then
      begin
        lblStatic5.Font.Color := clDkGray;
        lblStatic5.Caption := L_GET('txt.bf2nope');
        Result := Result + 2;
      end else
      begin
        lblStatic5.Font.Color := clRed;
        lblStatic5.Caption := L_GET('txt.bf2inv');
        Result := Result + 2;
      end;
    end;
  except
    Result := Result + 2;
  end;
end;


function TMainForm.GetKeys: Byte;
var
  KeyBF2, KeySF: String;
begin
  Result := 0;
  // Get BF2
  try
    KeyBF2 := GetBF2Key;
    if (Length(KeyBF2) < c_bfkeysize) then
    begin
      Result := 1;
    end else
    begin
      SetLength(KeyBF2, c_bfkeysize);
      Self.BF2Key := KeyBF2;
      edt1Key1p.Caption := Copy(KeyBF2, 1, 4);
      edt1Key2p.Caption := Copy(KeyBF2, 5, 4);
      edt1Key3p.Caption := Copy(KeyBF2, 9, 4);
      edt1Key4p.Caption := Copy(KeyBF2, 13, 4);
      edt1Key5p.Caption := Copy(KeyBF2, 17, 4);
    end;
  except
    Result := 1;
  end;
  // Get BF2SF
  try
    KeySF := GetBF2SFKey;
    if (Length(KeySF) < c_bfkeysize) then
    begin
      Result := 2;
    end else
    begin
      SetLength(KeySF, c_bfkeysize);
      Self.BF2SFKey := KeySF;
      edt2Key1p.Caption := Copy(KeySF, 1, 4);
      edt2Key2p.Caption := Copy(KeySF, 5, 4);
      edt2Key3p.Caption := Copy(KeySF, 9, 4);
      edt2Key4p.Caption := Copy(KeySF, 13, 4);
      edt2Key5p.Caption := Copy(KeySF, 17, 4);
    end;
  except
    Result := 2;
  end;
end;

function TMainForm.FillBF2Key(Key: String): Byte;
var
  KS: String;
begin
  Result := 0;
  // BF2
  try
    KS := Key;
    if (Length(KS) < c_bfkeysize) then
    begin
      Result := 1;
    end else
    begin
      SetLength(KS, c_bfkeysize);
      Self.BF2Key := KS;
      edt1Key1p.Caption := Copy(KS, 1, 4);
      edt1Key2p.Caption := Copy(KS, 5, 4);
      edt1Key3p.Caption := Copy(KS, 9, 4);
      edt1Key4p.Caption := Copy(KS, 13, 4);
      edt1Key5p.Caption := Copy(KS, 17, 4);
    end;
  except
    Result := 1;
  end;
end;

function TMainForm.FillSFKey(Key: String): Byte;
var
  KS: String;
begin
  Result := 0;
  // BF2SF
  try
    KS := Key;
    if (Length(KS) < c_bfkeysize) then
    begin
      Result := 1;
    end else
    begin
      SetLength(KS, c_bfkeysize);
      Self.BF2SFKey := KS;
      edt2Key1p.Caption := Copy(KS, 1, 4);
      edt2Key2p.Caption := Copy(KS, 5, 4);
      edt2Key3p.Caption := Copy(KS, 9, 4);
      edt2Key4p.Caption := Copy(KS, 13, 4);
      edt2Key5p.Caption := Copy(KS, 17, 4);
    end;
  except
    Result := 1;
  end;
end;

function TMainForm.SetKeys: Byte;
var
  KeyBF2, KeySF: String;
begin
  Result := 0;
  // Set BF2
  KeyBF2 := '';
  try
    KeyBF2 := KeyBF2 + edt1Key1p.Caption;
    KeyBF2 := KeyBF2 + edt1Key2p.Caption;
    KeyBF2 := KeyBF2 + edt1Key3p.Caption;
    KeyBF2 := KeyBF2 + edt1Key4p.Caption;
    KeyBF2 := KeyBF2 + edt1Key5p.Caption;
    if (Length(KeyBF2) = c_bfkeysize) then
    begin
      if (SetBF2Key('', KeyBF2+#0) > 0)
      then Result := Result + 1
      else BF2Key := KeyBF2;
    end else
    begin
      Result := Result + 1;
    end;
  except
    Result := Result + 1;
  end;
  // Set BF2SF
  KeySF := '';
  try
    KeySF := KeySF + edt2Key1p.Caption;
    KeySF := KeySF + edt2Key2p.Caption;
    KeySF := KeySF + edt2Key3p.Caption;
    KeySF := KeySF + edt2Key4p.Caption;
    KeySF := KeySF + edt2Key5p.Caption;
    if (Length(KeySF) = c_bfkeysize) then
    begin
      if (SetBF2SFKey('', KeySF+#0) > 0)
      then Result := Result + 2
      else BF2SFKey := KeySF;
    end else
    begin
      Result := Result + 2;
    end;
  except
    Result := Result + 2;
  end;
end;

procedure TMainForm.edt1keyChange(Sender: TObject);
begin
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.edt2keyChange(Sender: TObject);
begin
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.btnApplyClick(Sender: TObject);
begin
  { Set Keys }
  SetKeys;
  ChkKeys;
end;

procedure TMainForm.btnRandClick(Sender: TObject);
begin
  { Random Keys }
  GenKeys;
end;

procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  { Terminate }
  Application.Terminate;
end;

destructor TMainForm.Destroy;
begin
  inherited Destroy;
end;

end.
