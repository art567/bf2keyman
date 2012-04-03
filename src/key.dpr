program key;

uses
  Forms,
  main in 'main.pas',
  crypt in 'crypt.pas';

{$R *.res}

begin
  InitLocalization;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
