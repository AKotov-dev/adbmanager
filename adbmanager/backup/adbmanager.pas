program ADBManager;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,    {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  ADBDeviceStatusTRD,
  ADBCommandTRD,
  RebootUnit,
  SDCardManager,
  SDCommandTRD,
  LSSDFolderTRD,
  EmulatorUnit,
  SDMountPointTRD,
  CheckUnit,
  readappstrd,
  Settings_Unit,
  readsettingstrd,
  XDGOpenTRD,
  CPUTemperatureTRD;

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='ADBManager v4.0';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.CreateForm(TCheckForm, CheckForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.CreateForm(TEmulatorForm, EmulatorForm);
  Application.CreateForm(TRebootForm, RebootForm);
  Application.Run;
end.
