unit ADBDeviceStatusTRD;

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

//Scan ADB-device, status and adbkey
procedure ShowStatus.Execute;
var
  ExProcess: TProcess;
begin
  try
    FreeOnTerminate := True; //Уничтожать по завершении
    Result := TStringList.Create;

    //Вывод состояния ADB, списка устройств
    ExProcess := TProcess.Create(nil);
    ExProcess.Options := [poUsePipes, poWaitOnExit];
    ExProcess.Executable := 'bash';

    while not Terminated do
    begin
      Result.Clear;
      Exprocess.Parameters.Clear;

      //Устройство + статус
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('adb devices | tail -n +2');
      ExProcess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowDevices);

      //Status-is-active?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('ss -lt | grep 5037');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowIsActive);

      //Key exists?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('ls ~/.android | grep adbkey');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowKey);

      Sleep(300);
    end;

  finally
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СТАТУСА }

//Состояние ключей
procedure ShowStatus.ShowKey;
begin
  if Result.Count <> 0 then
    MainForm.KeyLabel.Caption := SYes
  else
    MainForm.KeyLabel.Caption := SNo;

  MainForm.KeyLabel.Repaint;
end;

//Вывод активности ADB
procedure ShowStatus.ShowIsActive;
begin
  if Result.Count <> 0 then
    MainForm.ActiveLabel.Caption := SLaunched
  else
    MainForm.ActiveLabel.Caption := SRestart;

  MainForm.ActiveLabel.Repaint;
end;

//Вывод найденного устройства и статуса
procedure ShowStatus.ShowDevices;
var
  i: integer;
  dev0, dev1, adbcmd: string;
begin
  //Удаляем начальные и конечные переводы строки/пробелы
  Result.Text := Trim(Result.Text);

  //Больше одного устройства? Переключаем на последнее
  if Result.Count > 1 then
  begin
    adbcmd := '';

    //Состояние offline - перезапуск adb (состязание двух устройств)
    if Pos('offline', Result.Text) <> 0 then
      MainForm.StartProcess('killall adb; adb kill-server >/dev/null 2>&1');

    i := Pos(#9, Result[0]); //Выделяем имя-1
    dev0 := Trim(Copy(Result[0], 1, i));
    i := Pos(#9, Result[1]); //Выделяем имя-2
    dev1 := Trim(Copy(Result[1], 1, i));

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
    {if SDForm.Visible then
      SDForm.Close;

    //Отключаем терминал, если использовался
    MainForm.StartProcess('[ $(pidof sakura) ] && killall sakura');}

      StartADBCommand.Create(adbcmd);
    end;
  end
  else //Единственное устройство и статус выводим сразу, либо "no device"
  if Result.Text <> '' then
    MainForm.DevSheet.Caption := Result[0]
  else
    MainForm.DevSheet.Caption := SNoDevice;
end;

end.
