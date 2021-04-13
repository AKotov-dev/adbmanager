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

//Scan ADB-devices, status and adbkey
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

      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('adb devices | tail -n +2');

      ExProcess.Execute;

      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowDevices);

      //Status-is-active?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('netstat -lt | grep 5037');

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

//Вывод IsActive
procedure ShowStatus.ShowIsActive;
begin
  if Result.Count <> 0 then
  MainForm.ActiveLabel.Caption := 'active' else
    MainForm.ActiveLabel.Caption := 'inactive';
end;

//Вывод списка устройств
procedure ShowStatus.ShowDevices;
begin
  MainForm.DevicesBox.Items.Assign(Result);
end;

end.

