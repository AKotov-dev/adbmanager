program adbmanager;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX}
  cthreads, {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, ShowStatusTRD, ADBCommandTRD, rebootunit, BackUpUnit,
  SDCardManager, SDCommandTRD { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='ADBManager v0.9';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TRebootForm, RebootForm);
  Application.CreateForm(TBackupForm, BackupForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.Run;
end.

