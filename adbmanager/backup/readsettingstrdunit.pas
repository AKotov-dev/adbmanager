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

uses Unit1, Settings_Unit;

  { TRD }

//Чтение параметров Settings
procedure TReadSettingsTRD.Execute;
var
  j: integer;
  Output: string;
  Command: TStringList;
begin
  try
    Synchronize(@StartRead);

    Command := TStringList.Create;

    //Список команд
    //0 SSystemSound
    Command.Add('adb shell settings get system sound_effects_enabled');
    //1 SVibration
    Command.Add('adb shell settings get system haptic_feedback_enabled');
    //2 SSecNotifications
    Command.Add('adb shell settings get global device_provisioned');
    //3 SAutomaticSync
    Command.Add('adb shell settings get global auto_sync');
    //4 SInterfaceAnimation1
    Command.Add('adb shell settings get global transition_animation_scale');
    //5 SInterfaceAnimation2
    Command.Add('adb shell settings get global animator_duration_scale');
    //6 SInterfaceAnimation3
    Command.Add('adb shell settings get global window_animation_scale');
    //7 SAutoRotateScreen
    Command.Add('adb shell settings get system accelerometer_rotation');
    //8 SAutoUpdate
    Command.Add('adb shell settings get global auto_update');
    //9 SPowerSavingMode
    Command.Add('adb shell settings get global low_power');

    //Выполняем команды
    for j := 0 to Command.Count - 1 do
    begin
      FOutput := '';
      if RunCommand('bash', ['-c', Command[j]], Output, [poWaitOnExit, poUsePipes]) then
        FOutput := Trim(Output);

      FIndex := j;

      //Выводим
      if Terminated then Exit;
      if FOutput <> '' then
        Synchronize(@ShowValue);
    end;

    //Уровень громкости
    FOutput := '';
    if RunCommand('bash', ['-c', 'adb shell media volume --stream 3 --get | grep -oP ' +
      '''' + 'volume is \K[0-9]+' + ''''], Output, [poWaitOnExit, poUsePipes]) then

      FOutput := Trim(Output);

    if Terminated then Exit;
    if FOutput <> '' then
      Synchronize(@ShowVolume);

    //Размер шрифта
    FOutput := '';
    if RunCommand('bash', ['-c', 'adb shell settings get system font_scale'],
      Output, [poWaitOnExit, poUsePipes]) then
      FOutput := Trim(Output);

    if Terminated then Exit;
    if FOutput <> '' then
      Synchronize(@ShowFontSize);

  finally
    Synchronize(@StopRead);
    FOutput := '';
    FIndex := -1;
    Command.Free;
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
  MainForm.SettingsBtn.Enabled := False;
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
  MainForm.SettingsBtn.Enabled := False;
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
