unit Settings_Unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, ComCtrls, IniFiles, ReadSettingsTRDUnit, CPUTemperature;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    CheckGroup1: TCheckGroup;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    CPUTemp: TLabel;
    ProgressBar1: TProgressBar;
    ApplyBtn: TSpeedButton;
    TrackBar1: TTrackBar;
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SaveSettings;
    procedure LoadSettings;

  private
    FReadSettingsTRD: TReadSettingsTRD;
    FCPUTempTRD: TCPUTempTRD;

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

uses unit1, ADBCommandTRD;

  {$R *.lfm}

  { TSettingsForm }

//Сохранение настроек формы
procedure TSettingsForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(CONF);
  try
    Ini.WriteInteger('SettingsForm', 'Top', SettingsForm.Top);
    Ini.WriteInteger('SettingsForm', 'Left', SettingsForm.Left);
    Ini.WriteInteger('SettingsForm', 'Width', SettingsForm.Width);
    Ini.WriteInteger('SettingsForm', 'Height', SettingsForm.Height);
  finally
    Ini.Free;
  end;
end;

//Загрузка настроек формы
procedure TSettingsForm.LoadSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(CONF) then Exit;
  Ini := TIniFile.Create(CONF);
  try
    SettingsForm.Top := Ini.ReadInteger('SettingsForm', 'Top', SettingsForm.Top);
    SettingsForm.Left := Ini.ReadInteger('SettingsForm', 'Left', SettingsForm.Left);
    SettingsForm.Width := Ini.ReadInteger('SettingsForm', 'Width', SettingsForm.Width);
    SettingsForm.Height := Ini.ReadInteger('SettingsForm', 'Height',
      SettingsForm.Height);
  finally
    Ini.Free;
  end;
end;

//Показ формы
procedure TSettingsForm.FormShow(Sender: TObject);
var
  i: integer;
begin
  //For Plasma
  LoadSettings;

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

  //Показываем температуру процессора
  if not Assigned(FCPUTempTRD) then
  begin
    FCPUTempTRD := TCPUTempTRD.Create(True);
    FCPUTempTRD.Start;
  end;

  //Запуск потока чтения настроек
  if not Assigned(FReadSettingsTRD) then
  begin
    FReadSettingsTRD := TReadSettingsTRD.Create(True);
    FReadSettingsTRD.Start;
  end;
end;

procedure TSettingsForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // Убиваем все adb push, adb pull процессы одной командой
 // MainForm.StartProcess('pkill -f "adb shell settings"');

  if Assigned(FReadSettingsTRD) then
  begin
    FReadSettingsTRD.Terminate;
    FReadSettingsTRD.WaitFor;
    FreeAndNil(FReadSettingsTRD);
  end;

  if Assigned(FCPUTempTRD) then
  begin
    FCPUTempTRD.Terminate;
    FCPUTempTRD.WaitFor;
    FreeAndNil(FCPUTempTRD);
  end;

  Sleep(20);
  SaveSettings;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

//Применить
procedure TSettingsForm.ApplyBtnClick(Sender: TObject);
var
  j: integer;
  CheckStr, adbcmd: string;
  Command: TStringList;
begin
  try
    Command := TStringList.Create;

    // Список команд с привязкой к чекерам
    Command.Add('adb shell settings put system sound_effects_enabled');
    Command.Add('adb shell settings put system haptic_feedback_enabled');
    Command.Add('adb shell settings put global device_provisioned');
    Command.Add('adb shell settings put global auto_sync');
    Command.Add('adb shell settings put global transition_animation_scale');
    Command.Add('adb shell settings put global animator_duration_scale');
    Command.Add('adb shell settings put global window_animation_scale');
    Command.Add('adb shell settings put system accelerometer_rotation');
    Command.Add('adb shell settings put global auto_update');
    Command.Add('adb shell settings put global low_power');

    // Цикл записи чекеров
    for j := 0 to Command.Count - 1 do
    begin

      if CheckGroup1.Checked[j] then
        CheckStr := '1'
      else
        CheckStr := '0';

      adbcmd := adbcmd + Command[j] + ' ' + CheckStr + '; ';
    end;
    // Запись громкости
    adbcmd := adbcmd + 'adb shell media volume --stream 3 --set ' +
      IntToStr(SettingsForm.TrackBar1.Position) + '; ';

    // Запись размера шрифта
    adbcmd := adbcmd + 'adb shell settings put system font_scale ' +
      Trim(ComboBox1.Text);

    if adbcmd <> '' then
      StartADBCommand.Create(adbcmd);

    Close;

  finally
    Command.Free;
  end;
end;

end.
