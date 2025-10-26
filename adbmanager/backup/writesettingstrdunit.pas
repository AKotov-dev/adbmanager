unit WriteSettingsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, Process;

type
  TWriteSettingsTRD = class(TThread)
  private
    FOutput: string; // Для возможного вывода ошибок
  protected
    procedure Execute; override;

    procedure StartWrite;
    procedure StopWrite;
  end;

implementation

uses settings_unit;

procedure TWriteSettingsTRD.Execute;
var
  j: integer;
  CheckStr, Output: string;
  Command: TStringList;
begin
  try
    Synchronize(@StartWrite);

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
      if Terminated then Exit;

      if SettingsForm.CheckGroup1.Checked[j] then
        CheckStr := '1'
      else
        CheckStr := '0';

      // Выполнение команды через RunCommand
      RunCommand('bash', ['-c', Command[j] + ' ' + CheckStr], Output,
        [poWaitOnExit, poUsePipes]);
    end;

    // Запись громкости
    if not Terminated then
      RunCommand('bash', ['-c', 'adb shell media volume --stream 3 --set ' +
        IntToStr(SettingsForm.TrackBar1.Position)],
        Output, [poWaitOnExit, poUsePipes]);

    // Запись размера шрифта
    if not Terminated then
      RunCommand('bash', ['-c', 'adb shell settings put system font_scale ' +
        SettingsForm.ComboBox1.Text],
        Output, [poWaitOnExit, poUsePipes]);

  finally
    Command.Free;
    Synchronize(@StopWrite);
  end;
end;

// Старт записи настроек
procedure TWriteSettingsTRD.StartWrite;
begin
  if Assigned(SettingsForm) then
    with SettingsForm do
    begin
      ApplyBtn.Enabled := False;
      ProgressBar1.Style := pbstMarquee;
      ProgressBar1.Visible := True;
      ProgressBar1.Repaint;
    end;
end;

// Стоп записи настроек
procedure TWriteSettingsTRD.StopWrite;
begin
  if Assigned(SettingsForm) then
    with SettingsForm do
    begin
      ApplyBtn.Enabled := True;
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Visible := False;
      ProgressBar1.Repaint;
      Close;
    end;
end;

end.
