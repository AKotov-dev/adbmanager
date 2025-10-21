unit WriteSettingsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  WriteSettingsTRD = class(TThread)
  private

    { Private declarations }
  protected

    procedure Execute; override;

    procedure StartRead;
    procedure StopRead;

  end;

implementation

uses settings_unit;

  { TRD }

//Запись параметров Settings
procedure WriteSettingsTRD.Execute;
var
  j: integer;
  CheckStr: string;
  Command: TStringList;
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartRead);

    Command := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

    //Список команд
    //0 SSystemSound
    Command.Add('adb shell settings put system sound_effects_enabled');
    //1 SVibration
    Command.Add('adb shell settings put system haptic_feedback_enabled');
    //2 SSecNotifications
    Command.Add('adb shell settings put global device_provisioned');
    //3 SAutomaticSync
    Command.Add('adb shell settings put global auto_sync');
    //4 SInterfaceAnimation1
    Command.Add('adb shell settings put global transition_animation_scale');
    //5 SInterfaceAnimation2
    Command.Add('adb shell settings put global animator_duration_scale');
    //6 SInterfaceAnimation3
    Command.Add('adb shell settings put global window_animation_scale');
    //7 SAutoRotateScreen
    Command.Add('adb shell settings put system accelerometer_rotation');
    //8 SAutoUpdate
    Command.Add('adb shell settings put global auto_update');
    //9 SPowerSavingMode
    Command.Add('adb shell settings put global low_power');

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Options := [poUsePipes, poWaitOnExit]; //poWaitOnExit, poStderrToOutPut
    ExProcess.Parameters.Add(':;');

    //Расстановка чекеров
    for j := 0 to Command.Count - 1 do
    begin
      ExProcess.Parameters.Delete(1);

      if SettingsForm.CheckGroup1.Checked[j] = True then CheckStr := '1'
      else
        CheckStr := '0';

      ExProcess.Parameters.Add(Command[j] + ' ' + CheckStr);

      ExProcess.Execute;
    end;

    //Уровень громкости
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell media volume --stream 3 --set ' +
      IntToStr(SettingsForm.TrackBar1.Position));
    ExProcess.Execute;


    //Размер шрифта
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell settings put system font_scale ' +
      SettingsForm.ComboBox1.Text);
    ExProcess.Execute;

  finally
    Synchronize(@StopRead);
    Command.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СПИСКА ПРИЛОЖЕНИЙ }

//Старт
procedure WriteSettingsTRD.StartRead;
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
procedure WriteSettingsTRD.StopRead;
begin
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
