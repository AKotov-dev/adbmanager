program adbmanager;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,    {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, ADBDeviceStatusTRD, ADBCommandTRD, RebootUnit, SDCardManager,
  SDCommandTRD, LSSDFolderTRD, EmulatorUnit, SDMountPointTRD, CheckUnit,
  ReadAppsTRDUnit, settings_unit, ReadSettingsTRDUnit, WriteSettingsTRDUnit { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='ADBManager v3.4';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSDForm, SDForm);
  Application.CreateForm(TCheckForm, CheckForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  Application.Run;
end.
