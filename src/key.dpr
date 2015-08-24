program key;

uses
  Forms,
  main in 'main.pas',
  crypt in 'crypt.pas';

{$R app_main.res}
{$R app_manifest.res}
{$R app_version.res}

begin
  InitLocalization;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
