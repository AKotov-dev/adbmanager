unit ADBDeviceStatusTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

type
  TRAMInfo = record
    TotalGB: double;
    AvailGB: double;
    Percent: double;
  end;

  ShowStatus = class(TThread)

  private
    FInfo: TRAMInfo;
    function DeviceReachable(Device: string): boolean;
    { Private declarations }

  protected
  var
    SResult: TStringList;

    procedure Execute; override;

    procedure ShowDevices;
    procedure ShowIsActive;
    procedure ShowKey;
    procedure UpdateRAMLabel;

  end;

implementation

uses Unit1, SDCardManager, ADBCommandTRD;

function ShowStatus.DeviceReachable(Device: string): boolean;
var
  P: TProcess;
  IPOnly: string;
begin
  Result := False;
  if Pos(':', Device) > 0 then
  begin
    IPOnly := Copy(Device, 1, Pos(':', Device) - 1);
    P := TProcess.Create(nil);
    try
      P.Executable := '/bin/bash';
      P.Parameters.Add('-c');
      P.Parameters.Add(Format('ping -c 1 -W 1 %s >/dev/null 2>&1', [IPOnly]));
      P.Options := [poWaitOnExit];
      P.Execute;
      Result := (P.ExitStatus = 0);
    finally
      P.Free;
    end;
  end
  else
    Result := True; // USB устройство всегда доступно
end;

//Scan ADB-device, Status, RAM и ADBKey (с очисткой пайпов)
procedure ShowStatus.Execute;
var
  Output: string;
  Line, SLine, S: string;
  TotalKB, AvailKB: int64;
  MemFree, Buffers, Cached: int64;
begin
  FreeOnTerminate := True;
  SResult := TStringList.Create;
  try
    while not Terminated do
    begin
      // -------------------------
      // 1. Проверка ADB сервера
      // -------------------------
      if RunCommand('bash', ['-c', 'ss -lt | grep 5037'], Output,
        [poWaitOnExit, poUsePipes]) then
      begin
        SResult.Text := Trim(Output);
      end
      else
        SResult.Clear;

      Synchronize(@ShowIsActive);

      //Если ADB не запущен - запустить
      if SResult.Count = 0 then
        RunCommand('bash', ['-c', 'adb start-server'], Output, [poWaitOnExit]);

      // -------------------------
      // 2. Если ADB запущен - Получение списка устройств
      // -------------------------
      if SResult.Count <> 0 then
      begin
        if RunCommand('bash', ['-c', 'adb devices | tail -n +2'],
          Output, [poWaitOnExit, poUsePipes]) then
        begin
          SResult.Text := Trim(Output);

          //Состояние offline - перезапуск adb (состязание двух устройств)
          if (SResult.Count > 1) and (Pos('offline', SResult.Text) <> 0) then
          begin
            RunCommand('bash',
              ['-c', 'killall adb; adb kill-server; adb start-server'], Output,
              [poWaitOnExit]);
            Sleep(300); //Для чёткого старта ADB
          end;
        end;
      end
      else
        SResult.Clear;

      if not Terminated then
        Synchronize(@ShowDevices);

      //Вывод памяти устройства (RAM)

      TotalKB := 0;
      AvailKB := 0;
      MemFree := 0;
      Buffers := 0;
      Cached := 0;

      //Отслеживаем состояние устройства, в это время память = 0
      if (SResult.Count = 1) and (Pos('offline', SResult.Text) = 0) and
        (Pos('unauthorized', SResult.Text) = 0) then
      begin
        //Устройство доступно по USB или по IP?
        if DeviceReachable(SResult[0]) then
        begin
          if RunCommand('bash', ['-c', 'adb shell cat /proc/meminfo'],
            Output, [poWaitOnExit, poUsePipes]) then
          begin
            SResult.Text := Output;

            for Line in SResult do
            begin
              try
                SLine := Trim(Line);

                if Pos('MemTotal', SLine) > 0 then
                begin
                  S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                  S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                  Val(S, TotalKB);
                end
                else if Pos('MemAvailable', SLine) > 0 then
                begin
                  S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                  S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                  Val(S, AvailKB);
                end
                else if Pos('MemFree', SLine) > 0 then
                begin
                  S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                  S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                  Val(S, MemFree);
                end
                else if Pos('Buffers', SLine) > 0 then
                begin
                  S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                  S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                  Val(S, Buffers);
                end
                else if Pos('Cached', SLine) > 0 then
                begin
                  S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                  S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                  Val(S, Cached);
                end;
              finally
              end;
              // adb отвалился — оставляем нули
            end;
          end;
        end;

        if AvailKB = 0 then
          AvailKB := MemFree + Buffers + Cached;

        if TotalKB > 0 then
        begin
          FInfo.TotalGB := TotalKB / 1024 / 1024;
          FInfo.AvailGB := AvailKB / 1024 / 1024;
          FInfo.Percent := (AvailKB * 100) / TotalKB;
        end
        else
        begin
          FInfo.TotalGB := 0;
          FInfo.AvailGB := 0;
          FInfo.Percent := 0;
        end;
      end
      else
      begin
        // нет устройства или не пингуется
        FInfo.TotalGB := 0;
        FInfo.AvailGB := 0;
        FInfo.Percent := 0;
      end;

      if not Terminated then
        Synchronize(@UpdateRAMLabel);

      // -------------------------
      // 3. Проверка ключей
      // -------------------------
      if RunCommand('bash', ['-c', 'ls ~/.android/adbkey*'], Output,
        [poWaitOnExit, poUsePipes]) then
        SResult.Text := Trim(Output)
      else
        SResult.Clear;

      if not Terminated then
        Synchronize(@ShowKey);

      Sleep(300); // оптимальный интервал для CPU
    end;
  finally
    SResult.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СТАТУСА }

procedure ShowStatus.UpdateRAMLabel;
begin
  if Assigned(MainForm) and Assigned(MainForm.LabelRAM) then
    MainForm.LabelRAM.Caption :=
      Format('RAM: %.2f GB / %.2f GB (%.1f%%)',
      [FInfo.TotalGB, FInfo.AvailGB, FInfo.Percent]);
end;

//Вывод активности ADB
procedure ShowStatus.ShowIsActive;
begin
  if SResult.Count <> 0 then
    MainForm.ActiveLabel.Caption := SLaunched
  else
    MainForm.ActiveLabel.Caption := SRestart;

  MainForm.ActiveLabel.Repaint;
end;

//Состояние ключей
procedure ShowStatus.ShowKey;
begin
  if SResult.Count <> 0 then
    MainForm.KeyLabel.Caption := SYes
  else
    MainForm.KeyLabel.Caption := SNo;

  MainForm.KeyLabel.Repaint;
end;

//Вывод найденного устройства и статуса
procedure ShowStatus.ShowDevices;
var
  i: integer;
  dev0, dev1, adbcmd: string;
begin
  //Удаляем начальные и конечные переводы строки/пробелы
  SResult.Text := Trim(SResult.Text);

  //Больше одного устройства? Переключаем на последнее
  if SResult.Count > 1 then
  begin
    adbcmd := '';

    i := Pos(#9, SResult[0]); //Выделяем имя-1
    dev0 := Trim(Copy(SResult[0], 1, i));
    i := Pos(#9, SResult[1]); //Выделяем имя-2
    dev1 := Trim(Copy(SResult[1], 1, i));

    //Disconnect уже активного (1 или 2) и Connect существующего (если по IP)
    if Pos(dev0, MainForm.DevSheet.Caption) <> 0 then
    begin
      if Pos(':', dev1) <> 0 then //Если tcpip
        adbcmd := 'adb disconnect ' + dev0;
    end
    else
    if Pos(':', dev0) <> 0 then //Если tcpip
      adbcmd := 'adb disconnect ' + dev1;

    //USB в приоритете!
    if (Pos(':', dev0) <> 0) and (Pos(':', dev1) = 0) then
      adbcmd := 'adb disconnect ' + dev0
    else
    if (Pos(':', dev1) <> 0) and (Pos(':', dev0) = 0) then
      adbcmd := 'adb disconnect ' + dev1;

    //Запуск команды и потока отображения лога отключения
    if adbcmd <> '' then
    begin
      //Закрываем SD-Manager, если открыт
      if SDForm.Visible then
      begin
        SDForm.CancelCopy;
        SDForm.Close;
      end;

      //Отключаем терминал, если использовался
      MainForm.StartProcess('killall -q sakura');

      StartADBCommand.Create(adbcmd);
    end;
  end
  else //Единственное устройство и статус выводим сразу, либо "no device"
  if Trim(SResult.Text) <> '' then
    MainForm.DevSheet.Caption := SResult[0]
  else
    MainForm.DevSheet.Caption := SNoDevice;
end;

end.
