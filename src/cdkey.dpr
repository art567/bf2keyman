program cdkey;

//{$APPTYPE CONSOLE}

uses
  Windows, DateUtils, SysUtils, Registry, umd5;

const
  c_debug = 0;
  LFCR = #10+#13;

var
  vdebug: integer;
  vargc: integer;
  vargv: array[0..10] of string;
  vargl: ansistring;

//Required functions

function debug(in_val: byte = 255): boolean;
begin
  if (in_val = 0)
  then vdebug := 0;
  if (in_val = 1)
  then vdebug := 1;
  Result := false;
  if vdebug >= 1
  then Result := true;
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

function findparam(argc: integer; argv: array of string; inparam: string; cs: boolean = false): boolean;
var
  i: integer;
begin
  Result := False;
  for i:=1 to argc do
    begin
      if (not cs)
      then
        begin
          if (lowerCase(argv[i]) = inparam)
          then begin Result := True; exit; end;
        end
      else
        begin
          if (argv[i] = inparam)
          then begin Result := True; exit; end;
        end;
    end;
end;

function GenerateKey: ansistring;
var
  d: TDateTime;
  di: integer;
  ds: string;
  k0,k1,k2,k3,k4,k5,k6: ansistring;
begin
  d:= Date+Time;
  di:=DateTimeToUnix(d);
  ds:=inttostr(di);
  k0:='x939201000000';
  k1:= umd5.md5(umd5.md5(ds));
  k2:= umd5.md5(k1) + umd5.md5(ds + umd5.md5(ds) + umd5.md5(ds + umd5.md5(ds)));
  k3:= umd5.md5(k2) + umd5.md5(ds + ds + umd5.md5(ds) + umd5.md5(ds + umd5.md5(ds)));
  k4:= umd5.md5(k3) + umd5.md5(ds + ds + umd5.md5(ds) + umd5.md5(ds+ds) + umd5.md5(ds + umd5.md5(ds)));
  k5:= umd5.md5(k4) + umd5.md5(umd5.md5(k3)) + umd5.md5(k3) + umd5.md5(ds + ds + umd5.md5(ds) + umd5.md5(ds+ds) + umd5.md5(umd5.md5(ds)) + umd5.md5(ds + umd5.md5(ds)));
  k6:= umd5.md5(k5) + umd5.md5(umd5.md5(k4)) + umd5.md5(ds + ds + umd5.md5(ds) + umd5.md5(ds+ds) + umd5.md5(umd5.md5(ds)) + ds + umd5.md5(ds) + umd5.md5(ds+ds) + umd5.md5(umd5.md5(ds)) + umd5.md5(ds + umd5.md5(ds)));
  Result:=copy(k0+k1+k2+k3+k4+k5+k6, 0, 453);
end;

// Here is main program loop //

function Main(argc: integer; argv: array of string; argl: ansistring): integer;
var
  msg, key: ansistring;
begin
  Result := 0;
  if ( (findparam(argc, argv, '-debug')) or (findparam(argc, argv, '+debug')) or (findparam(argc, argv, '/debug')) or (findparam(argc, argv, '--debug')) )
  then debug(1);
  try
    key := GenerateKey;
  except
    // --------------------- error --------------------- //
    debug(1);
    if debug
    then MessageBox(0, 'Cannot generate key, aborting..', 'Error', MB_ICONERROR);
    Result := 1;
    exit;
    // ------------------------------------------------- //
  end;
  try
    // --------------------- debug --------------------- //
    msg := '*** DEBUG MODE ***'+LFCR+LFCR+
           'Executable: '+LFCR+argv[0]+LFCR+LFCR+
           'Command Line: '+LFCR+argl+LFCR+LFCR+
           'Key: '+LFCR+key+LFCR+LFCR+
           'Lenght: '+LFCR+inttostr(Length(GenerateKey));
    if debug
    then MessageBox(0, PAnsiChar(msg), 'Debug Message', MB_ICONASTERISK);
    // ------------------------------------------------- //
    SetRegistryData(HKEY_LOCAL_MACHINE, 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc', '', rdString, key);
    // --------------------- debug --------------------- //
    msg := '*** DEBUG MODE ***'+LFCR+LFCR+
           'Success: RegistryWriteKey()'+LFCR+LFCR+
           'Key: '+'HKEY_LOCAL_MACHINE\SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc'+LFCR+LFCR+
           'Value: '+key;
    if debug
    then MessageBox(0, PAnsiChar(msg), 'Debug Message', MB_ICONASTERISK);
    // ------------------------------------------------- //
    SetRegistryData(HKEY_LOCAL_MACHINE, 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc', '', rdString, key);
    // --------------------- debug --------------------- //
    msg := '*** DEBUG MODE ***'+LFCR+LFCR+
           'Success: RegistryWriteKey()'+LFCR+LFCR+
           'Key: '+'HKEY_LOCAL_MACHINE\SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc'+LFCR+LFCR+
           'Value: '+key;
    if debug
    then MessageBox(0, PAnsiChar(msg), 'Debug Message', MB_ICONASTERISK);
    // ------------------------------------------------- //
  except
    // --------------------- error --------------------- //
    debug(1);
    if debug
    then MessageBox(0, 'Cannot write registry, aborting..', 'Error', MB_ICONERROR);
    Result := 1;
    exit;
    // ------------------------------------------------- //
  end;
end;

// Program initilizator dummy //

begin
  vargv[0] := paramstr(0);
  vargl := vargv[0];
  if paramcount > 0
  then
    begin
      for vargc:=1 to paramcount do
        begin
          vargv[vargc] := paramstr(vargc);
          vargl := vargl + ' '+vargv[vargc];
        end;
    end;
  Main(paramcount, vargv, vargl);
end.
 