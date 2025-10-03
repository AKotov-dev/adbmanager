unit settings_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, IniPropStorage, ComCtrls;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    CheckGroup1: TCheckGroup;
    ComboBox1: TComboBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    ProgressBar1: TProgressBar;
    ApplyBtn: TSpeedButton;
    TrackBar1: TTrackBar;
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  SettingsForm: TSettingsForm;

resourcestring
  SSystemSound = 'System sounds such as clicks when buttons are pressed';
  SVibration = 'Vibration when pressing buttons or other actions';
  SSecNotifications =
    'Security notifications, such as notifications that the device is password protected';
  SAutomaticSync = 'Automatic synchronization of accounts (Google, Facebook, etc.)';
  SInterfaceAnimation1 =
    'Animation of transitions between screens and different states (transition_animation_scale)';
  SInterfaceAnimation2 =
    'Animation of button presses, scaling of elements (animator_duration_scale)';
  SInterfaceAnimation3 =
    'Animation of opening, closing and moving windows (window_animation_scale)';
  SAutoRotateScreen = 'Enable or disable auto-rotate screen';
  SAutoUpdate = 'Automatic system update';
  SPowerSavingMode = 'Power saving mode';


implementation

uses unit1, ReadSettingsTRDUnit, WriteSettingsTRDUnit;

  {$R *.lfm}

  { TSettingsForm }

//Показ формы
procedure TSettingsForm.FormShow(Sender: TObject);
var
  i: integer;
  FReadSettingsTRD: TThread;
begin
  //For Plasma
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
  IniPropStorage1.Restore;

  //Обнуляем все чеки для чистой загрузки из потока
  for i := 0 to CheckGroup1.Items.Count - 1 do
    CheckGroup1.Checked[i] := False;

  CheckGroup1.Items[0] := SSystemSound;
  CheckGroup1.Items[1] := SVibration;
  CheckGroup1.Items[2] := SSecNotifications;
  CheckGroup1.Items[3] := SAutomaticSync;
  CheckGroup1.Items[4] := SInterfaceAnimation1;
  CheckGroup1.Items[5] := SInterfaceAnimation2;
  CheckGroup1.Items[6] := SInterfaceAnimation3;
  CheckGroup1.Items[7] := SAutoRotateScreen;
  CheckGroup1.Items[8] := SAutoUpdate;
  CheckGroup1.Items[9] := SPowerSavingMode;

  //Уровень громкости
  TrackBar1.Position := 0;

  //Размер шрифта
  ComboBox1.Text := '...';

  //Запуск потока чтения настроек
  FReadSettingsTRD := ReadSettingsTRD.Create(False);
  FReadSettingsTRD.Priority := tpNormal;
end;

procedure TSettingsForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IniPropStorage1.Save;
end;

procedure TSettingsForm.ApplyBtnClick(Sender: TObject);
var
  FWriteSettingsTRD: TThread;
begin
  //Запуск потока записи настроек
  FWriteSettingsTRD := WriteSettingsTRD.Create(False);
  FWriteSettingsTRD.Priority := tpNormal;
end;

end.
