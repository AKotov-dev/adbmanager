unit CPUTemperature;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls, ComCtrls;

type
  TCPUTempTRD = class(TThread)
  private
    procedure ShowTemp;
  protected
    Output: string;
    procedure Execute; override;
  public

  end;

implementation

uses Settings_Unit;

// Основной код потока
procedure TCPUTempTRD.Execute;
begin
  try
    FreeOnTerminate := True;
    while not terminated do
    begin
      if RunCommand('bash', ['-c',
        'adb shell cat /sys/class/thermal/thermal_zone0/temp'],
        Output, [poWaitOnExit, poUsePipes]) then
      begin
        // Преобразуем полученное значение из миллиградусов в градусы Цельсия
        Output:= FormatFloat('0.0', StrToIntDef(Trim(Output),0)/1000) + ' °C'
      end
      else
        Output := '0.0';

      Synchronize(@ShowTemp);
      Sleep(500);
    end;
  finally
  end;
end;

// Показать температуру
procedure TCPUTempTRD.ShowTemp;
begin
  if Assigned(SettingsForm) then SettingsForm.CPUTemp.Caption := Output;
end;

end.
