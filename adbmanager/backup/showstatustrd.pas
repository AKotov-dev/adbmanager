unit ShowStatusTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Graphics;

type
  ShowStatus = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowDevices;
    procedure ShowIsActive;
    procedure ShowKey;

  end;

implementation

uses Unit1;

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
      ExProcess.Parameters.Add('lsof -n -i4TCP:5037 | grep LISTEN');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowIsActive);

      //Key exists?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('ls ~/.android | grep adbkey');
      Exprocess.Execute;

      Result.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowKey);

      Sleep(250);
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
    MainForm.KeyLabel.Caption := 'yes'
  else
    MainForm.KeyLabel.Caption := 'no';
end;

//Вывод активности ADB
procedure ShowStatus.ShowIsActive;
begin
  if Result.Count <> 0 then
    MainForm.ActiveLabel.Caption := 'active'
  else
    MainForm.ActiveLabel.Caption := 'launch...';
end;

//Вывод найденного устройства и статуса
procedure ShowStatus.ShowDevices;
var
  i: integer;
  dev0, dev1: string;
begin
  //Удаляем начальные и конечные переводы строки/пробелы
  Result.Text := Trim(Result.Text);

  //Больше одного устройства? Переключаем на последнее
  if Result.Count > 1 then
  begin
    i := Pos(#9, Result[0]);
    dev0 := Trim(Copy(Result[0], 1, i));
    i := Pos(#9, Result[1]);
    dev1 := Trim(Copy(Result[1], 1, i));

    if Result[0] = MainForm.DevSheet.Caption then
    begin
      MainForm.StartProcess('adb disconnect ' + dev0);
      if Pos(':', dev1) <> 0 then //Если tcpip
        MainForm.StartProcess('adb connect ' + dev1);
    end
    else
    begin
      MainForm.StartProcess('adb disconnect ' + dev1);
      if Pos(':', dev0) <> 0 then //Если tcpip
        MainForm.StartProcess('adb connect ' + dev0);
    end;
  end
  else //Единственное устройство и статус выводим сразу, либо "no device"
  if Result.Text <> '' then
    MainForm.DevSheet.Caption := Result[0]
  else
    MainForm.DevSheet.Caption := SNoDevice;
end;

end.
