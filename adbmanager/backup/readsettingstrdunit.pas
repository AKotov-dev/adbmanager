unit ReadSettingsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  TReadSettingsTRD = class(TThread)
  private
    FIndex: integer;
    //Поле для пересылки индекса чекера в Synchronize(@ShowValue);
    FOutput: string;
    //Поле для пересылки результатов громкости и шрифта

    { Private declarations }
  protected

    procedure Execute; override;

    procedure StartRead;
    procedure StopRead;

    procedure ShowValue;
    procedure ShowVolume;
    procedure ShowFontSize;

  end;

implementation

uses settings_unit;

  { TRD }

//Чтение параметров Settings
procedure TReadSettingsTRD.Execute;
var
  j: integer;
  Output, FullCmd: string;
  Lines: TStringList;
begin
  try
    Synchronize(@StartRead);

    // Формируем единый вызов adb shell
    FullCmd :=
      'adb shell "settings get system sound_effects_enabled;' +
      'settings get system haptic_feedback_enabled;' +
      'settings get global device_provisioned;' + 'settings get global auto_sync;' +
      'settings get global transition_animation_scale;' +
      'settings get global animator_duration_scale;' +
      'settings get global window_animation_scale;' +
      'settings get system accelerometer_rotation;' +
      'settings get global auto_update;' + 'settings get global low_power"';

    // Выполняем всё сразу
    if not RunCommand('bash', ['-c', FullCmd], Output, [poWaitOnExit, poUsePipes]) then
      Exit;

    // Разбиваем результат на строки
    Lines := TStringList.Create;
    try
      Lines.Text := Trim(Output);

      for j := 0 to Lines.Count - 1 do
      begin
        if Terminated then Exit;
        FIndex := j;
        FOutput := Trim(Lines[j]);
        Synchronize(@ShowValue);
      end;
    finally
      Lines.Free;
    end;

    // === Уровень громкости ===
    if Terminated then Exit;
    if RunCommand('bash', ['-c',
      'adb shell "media volume --stream 3 --get" | grep -oP ''volume is \K[0-9]+'''],
      Output, [poWaitOnExit, poUsePipes]) then
    begin
      FOutput := Trim(Output);
      if FOutput <> '' then
        Synchronize(@ShowVolume);
    end;

    // === Размер шрифта ===
    if Terminated then Exit;
    if RunCommand('bash', ['-c', 'adb shell settings get system font_scale'],
      Output, [poWaitOnExit, poUsePipes]) then
    begin
      FOutput := Trim(Output);
      if FOutput <> '' then
        Synchronize(@ShowFontSize);
    end;

  finally
    Synchronize(@StopRead);
    FOutput := '';
    FIndex := -1;
  end;
end;


{ БЛОК ОТОБРАЖЕНИЯ }

//Вывод чекеров
procedure TReadSettingsTRD.ShowValue;
begin
  if Assigned(SettingsForm) then
  begin
    if (FOutput = '1') or (FOutput = '1.0') then
      SettingsForm.CheckGroup1.Checked[FIndex] := True
    else
    if FOutput = 'null' then SettingsForm.CheckGroup1.Items[FIndex] :=
        '(NULL) ' + SettingsForm.CheckGroup1.Items[FIndex]
    else
      SettingsForm.CheckGroup1.Checked[FIndex] := False;
  end;
end;

//Уровень громкости
procedure TReadSettingsTRD.ShowVolume;
var
  IntValue: integer;
begin
  if Assigned(SettingsForm) then
  begin
    // Проверяем, можно ли преобразовать строку в число
    if TryStrToInt(FOutput, IntValue) then
      // Если число преобразовано, проверяем, лежит ли оно в пределах от 0 до 15
      if (IntValue >= 0) and (IntValue <= 15) then
        SettingsForm.TrackBar1.Position := StrToInt(FOutput);
  end;
end;

//Размер шрифта
procedure TReadSettingsTRD.ShowFontSize;
begin
  if Assigned(SettingsForm) then
  begin
    if FOutput <> '' then SettingsForm.ComboBox1.Text := FOutput;
  end;
end;

//Старт
procedure TReadSettingsTRD.StartRead;
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

//Стоп
procedure TReadSettingsTRD.StopRead;
begin
  if Assigned(SettingsForm) then
    with SettingsForm do
    begin
      ApplyBtn.Enabled := True;
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Visible := False;
      ProgressBar1.Repaint;
    end;
end;

end.
