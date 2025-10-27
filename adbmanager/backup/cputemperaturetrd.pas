unit CPUTemperatureTRD;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls, ComCtrls;

type
  TCPUTempTRD = class(TThread)
  private
    FOutput: string;
    procedure ShowTemp;
    function ReadTemperature: string;
  protected
    procedure Execute; override;
  end;

implementation

uses Settings_Unit;

{ === Чтение температуры === }
function TCPUTempTRD.ReadTemperature: string;
var
  Proc: TProcess;
  Buffer: array[0..1023] of byte;
  BytesRead: Integer;
  OutputStr: string;
begin
  Result := '0.0';
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := 'bash';
    Proc.Parameters.Add('-c');
    Proc.Parameters.Add('adb shell cat /sys/class/thermal/thermal_zone0/temp');
    Proc.Options := [poUsePipes, poNoConsole];
    Proc.Execute;

    // Читаем вывод с проверкой Terminated
    while Proc.Running do
    begin
      if Terminated then
      begin
        Proc.Terminate(0);
        Exit;
      end;

      if Proc.Output.NumBytesAvailable > 0 then
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          OutputStr := OutputStr + Copy(PAnsiChar(@Buffer[0]), 1, BytesRead);
      end;
      Sleep(10);
    end;

    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        OutputStr := OutputStr + Copy(PAnsiChar(@Buffer[0]), 1, BytesRead);
    end;

    OutputStr := Trim(OutputStr);
    if OutputStr <> '' then
      Result := FormatFloat('0.0', StrToIntDef(OutputStr, 0) / 1000) + ' °C';
  finally
    Proc.Free;
  end;
end;

{ === Основной поток === }
procedure TCPUTempTRD.Execute;
var
  i: Integer;
begin
  while not Terminated do
  begin
    FOutput := ReadTemperature;
    if Terminated then Exit;

    // Queue безопаснее при закрытии форм, чем Synchronize
    Queue(@ShowTemp);

    // Вместо Sleep(1000): проверяем Terminated каждые 10 мс
    for i := 0 to 99 do
    begin
      if Terminated then Exit;
      Sleep(10);
    end;
  end;
end;

{ === Отображение температуры === }
procedure TCPUTempTRD.ShowTemp;
begin
  if Assigned(SettingsForm) and Assigned(SettingsForm.CPUTemp) then
    SettingsForm.CPUTemp.Caption := FOutput;
end;

end.

