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

      ExProcess.Parameters.Add('-c');  // | grep -Ev "^$"  // grep devices
      ExProcess.Parameters.Add('adb devices | tail -n +2 | awk ' +
        '''' + '{ print $1 }' + '''');
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

//Вывод найденного устройства
procedure ShowStatus.ShowDevices;
begin
  //Удаляем начальные и конечные переводы строки/пробелы
  Result.Text := Trim(Result.Text);

  //Больше одного устройства? Переключаем на последнее
  if Result.Count > 1 then
  begin
    if Result[0] = MainForm.DevSheet.Caption then
    begin
      MainForm.StartProcess('adb disconnect ' + Result[0]);
      if Pos(':', Result[1]) <> 0 then //Если tcpip
        MainForm.StartProcess('adb connect ' + Result[1]);
    end
    else
    begin
      MainForm.StartProcess('adb disconnect ' + Result[1]);
      if Pos(':', Result[0]) <> 0 then //Если tcpip
        MainForm.StartProcess('adb connect ' + Result[0]);
    end;
  end
  else
  if Result.Text <> '' then
    MainForm.DevSheet.Caption := Result[0]
  else
    MainForm.DevSheet.Caption := SNoDevice;
end;

end.
