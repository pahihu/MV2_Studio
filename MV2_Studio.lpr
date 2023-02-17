program MV2_Studio;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, indylaz, Unit1, Unit2, Unit3, Unit4
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='MV2-Studio';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TStudioForm, StudioForm);
  Application.CreateForm(TOpenForm, OpenForm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.CreateForm(TSYNCHForm, SYNCHForm);
  Application.Run;
end.

