program adbmanager;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX}
  cthreads, {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, ADBDeviceStatusTRD, ADBCommandTRD, rebootunit, BackUpUnit,
  SDCardManager, SDCommandTRD, LSSDFolderTRD, EmulatorUnit { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='ADBManager v2.4';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.Run;
end.

