program adbmanager;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,   {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  ADBDeviceStatusTRD,
  ADBCommandTRD,
  RebootUnit,
  BackUpUnit,
  SDCardManager,
  SDCommandTRD,
  LSSDFolderTRD,
  EmulatorUnit,
  SDMountPointTRD,
  CheckUnit,
  ReadAppsTRDUnit { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='ADBManager v3.0';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.CreateForm(TCheckForm, CheckForm);
  Application.Run;
end.
