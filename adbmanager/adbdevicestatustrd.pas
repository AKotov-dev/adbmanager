unit ADBDeviceStatusTRD;
//Запуск ADB (если не запущен) при запуске приложения

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

type
  ShowStatus = class(TThread)
  private

    { Private declarations }
  protected
  var
    SResult: TStringList;

    procedure Execute; override;

    procedure ShowDevices;
    procedure ShowIsActive;
    procedure ShowKey;

  end;

implementation

uses Unit1, SDCardManager, ADBCommandTRD;

  { TRD }

//Scan ADB-device, status and adbkey (с очисткой пайпов)
procedure ShowStatus.Execute;
var
  S: string;
  ExProcess: TProcess;
begin
  FreeOnTerminate := True;
  SResult := TStringList.Create;
  ExProcess := TProcess.Create(nil);

  try
    ExProcess.Options := [poUsePipes, poWaitOnExit];
    ExProcess.Executable := 'bash';

    while not Terminated do
    begin
      // === Очистка состояния перед новой командой ===
      ExProcess.CloseOutput;       // сброс stdin
      ExProcess.Parameters.Clear;  // сброс параметров
      SResult.Clear;               // очистка вывода

      // === Проверка ADB сервера ===
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('ss -lt | grep 5037');
      ExProcess.Execute;
      SResult.LoadFromStream(ExProcess.Output);
      SResult.Text := Trim(SResult.Text);
      Synchronize(@ShowIsActive);

      //Если ADB не запущен - запустить
      if SResult.Count = 0 then
        RunCommand('bash', ['-c', 'adb start-server'], S, [poWaitOnExit]);

      // === Проверка устройств ===
      ExProcess.CloseOutput;
      ExProcess.Parameters.Clear;
      if SResult.Count <> 0 then
      begin
        SResult.Clear;
        ExProcess.Parameters.Add('-c');
        ExProcess.Parameters.Add('adb devices | tail -n +2');
        ExProcess.Execute;
        SResult.LoadFromStream(ExProcess.Output);
        SResult.Text := Trim(SResult.Text);
        //Состояние offline - перезапуск adb (состязание двух устройств)
        if (SResult.Count > 1) and (Pos('offline', SResult.Text) <> 0) then
          RunCommand('bash',
            ['-c', 'killall adb; adb kill-server; adb start-server'], S,
            [poWaitOnExit]);
      end
      else
        SResult.Clear;

      Synchronize(@ShowDevices);

      // === Проверка ключей ===
      ExProcess.CloseOutput;
      ExProcess.Parameters.Clear;
      SResult.Clear;
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('ls ~/.android/adbkey* 2>/dev/null');
      ExProcess.Execute;
      SResult.LoadFromStream(ExProcess.Output);
      SResult.Text := Trim(SResult.Text);
      Synchronize(@ShowKey);

      // === Сброс состояния процесса ===
      ExProcess.CloseOutput;

      if Assigned(ExProcess) and ExProcess.Running then
        ExProcess.Terminate(0);

      Sleep(300);
    end;

  finally
    SResult.Free;
    ExProcess.Free;
  end;
end;

{ //Scan ADB-device, status and adbkey (прежний вариант)
procedure ShowStatus.Execute;
var
  ExProcess: TProcess;
begin
  try
    FreeOnTerminate := True; //Уничтожать по завершении
    SResult := TStringList.Create;

    //Вывод состояния ADB, списка устройств
    ExProcess := TProcess.Create(nil);
    ExProcess.Options := [poUsePipes, poWaitOnExit];
    ExProcess.Executable := 'bash';

    while not Terminated do
    begin
      SResult.Clear;
      Exprocess.Parameters.Clear;
      ExProcess.Parameters.Add('-c');

      //ADB запущен?
      ExProcess.Parameters.Add('ss -lt | grep 5037');
      Exprocess.Execute;
      SResult.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowIsActive);

      //Если ADB запущен - показать Устройство
      if SResult.Count <> 0 then
      begin
        ExProcess.Parameters.Delete(1);
        ExProcess.Parameters.Add('adb devices | tail -n +2');
        ExProcess.Execute;
        SResult.LoadFromStream(ExProcess.Output);
      end
      else
        SResult.Clear;
      Synchronize(@ShowDevices);

      //Key exists?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('ls ~/.android/adbkey*');
      Exprocess.Execute;
      SResult.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowKey);

      Sleep(300);
    end;

  finally
    SResult.Free;
    ExProcess.Free;
    Terminate;
  end;
end; }


{ БЛОК ОТОБРАЖЕНИЯ СТАТУСА }

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
        SDForm.Close;

      //Отключаем терминал, если использовался
      MainForm.StartProcess('killall sakura');

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
