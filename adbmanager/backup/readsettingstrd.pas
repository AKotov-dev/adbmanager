unit ReadSettingsTRD;

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
  Command: TStringList;

  function RunADB(const Cmd: string): string;
  var
    Proc: TProcess;
    Buffer: array[0..2047] of byte;
    BytesRead: integer;
    OutputStr: string;
  begin
    Result := '';
    Proc := TProcess.Create(nil);
    try
      Proc.Executable := 'bash';
      Proc.Parameters.Add('-c');
      Proc.Parameters.Add(Cmd);
      Proc.Options := [poUsePipes, poNoConsole];
      Proc.Execute;

      // Читаем поток по кускам, с проверкой Terminated
      while Proc.Running do
      begin
        if Terminated then
        begin
          Proc.Terminate(0);
          Exit('');
        end;

        if Proc.Output.NumBytesAvailable > 0 then
        begin
          BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
          if BytesRead > 0 then
            OutputStr := OutputStr + Copy(pansichar(@Buffer[0]), 1, BytesRead);
        end;

        Sleep(10);
      end;

      // Дочитываем, если что-то осталось после завершения
      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          OutputStr := OutputStr + Copy(pansichar(@Buffer[0]), 1, BytesRead);
      end;

      Result := Trim(OutputStr);
    finally
      Proc.Free;
    end;
  end;

begin
  try
    Synchronize(@StartRead);

    Command := TStringList.Create;
    try
      // Список команд
      Command.Add('adb shell settings get system sound_effects_enabled');
      Command.Add('adb shell settings get system haptic_feedback_enabled');
      Command.Add('adb shell settings get global device_provisioned');
      Command.Add('adb shell settings get global auto_sync');
      Command.Add('adb shell settings get global transition_animation_scale');
      Command.Add('adb shell settings get global animator_duration_scale');
      Command.Add('adb shell settings get global window_animation_scale');
      Command.Add('adb shell settings get system accelerometer_rotation');
      Command.Add('adb shell settings get global auto_update');
      Command.Add('adb shell settings get global low_power');

      // Выполнение команд
      for j := 0 to Command.Count - 1 do
      begin
        if Terminated then Exit;
        FOutput := RunADB(Command[j]);
        FIndex := j;
        if (not Terminated) and (FOutput <> '') then
          Synchronize(@ShowValue);
      end;

      // Уровень громкости
      if Terminated then Exit;
      FOutput := RunADB(
        'adb shell media volume --stream 3 --get | grep -oP ''volume is \K[0-9]+''');
      if (not Terminated) and (FOutput <> '') then
        Synchronize(@ShowVolume);

      // Размер шрифта
      if Terminated then Exit;
      FOutput := RunADB('adb shell settings get system font_scale');
      if (not Terminated) and (FOutput <> '') then
        Synchronize(@ShowFontSize);

    finally
      Command.Free;
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
    with SettingsForm do
    begin
      if (FOutput = '1') or (FOutput = '1.0') then
        CheckGroup1.Checked[FIndex] := True
      else
      if FOutput = 'null' then CheckGroup1.Items[FIndex] :=
          '(NULL) ' + CheckGroup1.Items[FIndex]
      else
        CheckGroup1.Checked[FIndex] := False;
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
    if FOutput <> '' then SettingsForm.ComboBox1.Text := FOutput;
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
  MainForm.SettingsBtn.Enabled := True;
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
