program key;

uses
  Forms,
  Windows,
  SysUtils,
  main in 'main.pas',
  crypt in 'crypt.pas';

{$R app_main.res}
//{$R app_manifest.res}
{$R app_version.res}

var
  ma: byte;
  mk: byte;
  mf: byte;
  k: string;

const
  MA_DEFAULT  = $00;
  MA_APPLY    = $01;
  MK_DEFAULT  = $00;
  MK_MANUAL   = $01;
  MK_RANDOM   = $02;
  MK_HARDWARE = $04;
  MF_DEFAULT  = $00;
  MF_SILENT   = $10;

begin

  InitLocalization;

  ma := MA_DEFAULT;
  mk := MK_DEFAULT;
  mf := MF_DEFAULT;

  if (CmdSwitch('k') or CmdSwitch('key')) then
  begin
    mk := MK_MANUAL;
    k := EmptyStr;
    if (Length(CmdParam('k')) > 0) then
    begin
      k := CmdParam('k');
    end;
    if (Length(CmdParam('key')) > 0) then
    begin
      k := CmdParam('key');
    end;
    if (Length(k) > 0) then
    begin
      k := StringReplace(k, ' ', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '.', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, ':', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '+', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '-', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '=', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '/', '', [rfReplaceAll, rfIgnoreCase]);
      k := StringReplace(k, '\', '', [rfReplaceAll, rfIgnoreCase]);
    end;
  end;

  if (CmdSwitch('a') or CmdSwitch('app') or CmdSwitch('apply')) then
  begin
    ma := MA_APPLY;
  end;

  if (CmdSwitch('r') or CmdSwitch('rnd') or CmdSwitch('rand') or CmdSwitch('random')) then
  begin
    mk := MK_RANDOM;
    k := EmptyStr;
  end;

  if (CmdSwitch('hw') or CmdSwitch('hard') or CmdSwitch('hardware')) then
  begin
    mk := MK_HARDWARE;
    k := EmptyStr;
  end;

  if (CmdSwitch('s') or CmdSwitch('silent') or CmdSwitch('verysilent')) then
  begin
    mf := MF_SILENT;
  end;

  case mf of
    MF_SILENT:
    begin
      InitConsole();
      Title( 'Battlefield 2 :: Key Manager :: Silent mode' );
      Echo( '-= Battlefield 2 :: Key Manager :: Silent mode =-' );
      Echo( '=================================================' );
      case mk of
        MK_MANUAL:
        begin
          EchoU( 'Manual key = ' + k );
          //Sleep(1000);
          Echo ( ' .. OK.' );
        end;
        MK_RANDOM:
        begin
          EchoU( ' Random key = ' + k );
          //Sleep(1000);
          Echo ( ' .. OK.' );
        end;
        MK_HARDWARE:
        begin
          EchoU( ' Hardware key = ' + k );
          //Sleep(1000);
          Echo ( ' .. OK.' );
        end;
      else
      end;
      Echo( '=================================================' );
      Echo( 'Done.' );
      DeinitConsole();
      Exit;
    end;
  else
    begin
      Application.Initialize;
      Application.CreateForm(TMainForm, MainForm);
      case mk of
        MK_MANUAL:
        begin
          if ((MainForm.FillBF2Key(k) = 0) and (MainForm.FillSFKey(k) = 0)) then
          begin
            if (ma = MA_APPLY) then
            begin
              MainForm.SetKeys;
            end;
            Application.Run;
          end else
          begin
            MsgBox('Key provided is incorrect!', EmptyStr, MB_ICONERROR);
            Exit;
          end;
        end;
        MK_RANDOM:
        begin
          if ((MainForm.FillBF2Key(k) = 0) and (MainForm.FillSFKey(k) = 0)) then
          begin
            if (ma = MA_APPLY) then
            begin
              MainForm.SetKeys;
            end;
            Application.Run;
          end else
          begin
            MsgBox('Key provided is incorrect!', EmptyStr, MB_ICONERROR);
            Exit;
          end;
        end;
        MK_HARDWARE:
        begin
          if ((MainForm.FillBF2Key(k) = 0) and (MainForm.FillSFKey(k) = 0)) then
          begin
            if (ma = MA_APPLY) then
            begin
              MainForm.SetKeys;
            end;
            Application.Run;
          end else
          begin
            MsgBox('Key provided is incorrect!', EmptyStr, MB_ICONERROR);
            Exit;
          end;
        end;
      else
        Application.Run;
      end;
    end;
  end;
  
end.
