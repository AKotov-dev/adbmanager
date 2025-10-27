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
  ReadAppsTRDUnit,
  Settings_Unit,
  ReadSettingsTRDUnit,
  XDGOpenTRD,
  CPUTemperatureTRD;

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'ADBManager v3.9';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.CreateForm(TCheckForm, CheckForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.CreateForm(TEmulatorForm, EmulatorForm);
  Application.CreateForm(TRebootForm, RebootForm);
  Application.Run;
end.
