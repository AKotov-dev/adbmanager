unit ReadSettingsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  ReadSettingsTRD = class(TThread)
  private

    { Private declarations }
  protected
  var
    S, Command: TStringList;

    procedure Execute; override;

    procedure StartRead;
    procedure StopRead;

    procedure ShowValue;
    procedure ShowVolume;
    procedure ShowFontSize;

  end;

var
  j: integer;

implementation

uses settings_unit;

  { TRD }

//Чтение параметров Settings
procedure ReadSettingsTRD.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartRead);

    S := TStringList.Create;
    Command := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

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
    //10 SAllNotification
    Command.Add('adb shell settings get global zen_mode');

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Options := [poUsePipes, poWaitOnExit]; //poWaitOnExit, poStderrToOutPut
    ExProcess.Parameters.Add(':;');

    //Все приложения с сортировкой
    for j := 0 to Command.Count - 1 do
    begin
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add(Command[j]);

      ExProcess.Execute;
      S.LoadFromStream(ExProcess.Output);
      //Выводим
      S.Text := Trim(S.Text);
      if S.Count <> 0 then
        Synchronize(@ShowValue);
    end;

    //Уровень громкости
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell media volume --stream 3 --get | grep -oP ' +
      '''' + 'volume is \K[0-9]+' + '''');
    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);

    S.Text := Trim(S.Text);
    if S.Count <> 0 then
      Synchronize(@ShowVolume);

    //Размер шрифта
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell settings get system font_scale');
    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);

    S.Text := Trim(S.Text);
    if S.Count <> 0 then
      Synchronize(@ShowFontSize);


  finally
    Synchronize(@StopRead);
    S.Free;
    Command.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СПИСКА ПРИЛОЖЕНИЙ }

//Вывод чекеров
procedure ReadSettingsTRD.ShowValue;
begin
  if (S[0] = '1') or (S[0] = '1.0') then
    SettingsForm.CheckGroup1.Checked[j] := True
  else
  if S[0] = 'null' then SettingsForm.CheckGroup1.Items[j] :=
      '(NULL) ' + SettingsForm.CheckGroup1.Items[j]
  else
    SettingsForm.CheckGroup1.Checked[j] := False;
end;

//Уровень громкости
procedure ReadSettingsTRD.ShowVolume;
var
  IntValue: integer;
begin
  // Проверяем, можно ли преобразовать строку в число
  if TryStrToInt(S[0], IntValue) then
    // Если число преобразовано, проверяем, лежит ли оно в пределах от 0 до 15
    if (IntValue >= 0) and (IntValue <= 15) then
      SettingsForm.TrackBar1.Position := StrToInt(S[0]);
end;

//Размер шрифта
procedure ReadSettingsTRD.ShowFontSize;
begin
  if S[0] <> '' then SettingsForm.ComboBox1.Text := S[0];
end;

//Старт
procedure ReadSettingsTRD.StartRead;
begin
  with SettingsForm do
  begin
    ApplyBtn.Enabled := False;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Visible := True;
    ProgressBar1.Repaint;
  end;
end;

//Стоп
procedure ReadSettingsTRD.StopRead;
begin
  with SettingsForm do
  begin
    ApplyBtn.Enabled := True;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
    ProgressBar1.Repaint;
  end;
end;

end.
