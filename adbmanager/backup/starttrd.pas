unit StartTRD;

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
    procedure ShowIsEnabled;
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
      ExProcess.Parameters.Add('adb devices');

      ExProcess.Execute;

      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowDevices);

      //Status-is-active?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('systemctl is-active adb');

      Exprocess.Execute;
      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowIsActive);

      //Status-is-enabled?
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('systemctl is-enabled adb');

      Exprocess.Execute;
      Result.LoadFromStream(ExProcess.Output);

      if Result.Count <> 0 then
        Synchronize(@ShowIsEnabled);

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

//Статус IsEnabled
procedure ShowStatus.ShowIsEnabled;
begin
  MainForm.EnabledLabel.Caption := Trim(Result[0]);

  //EnableButton change
  if MainForm.EnabledLabel.Caption = 'disabled' then
  begin
    MainForm.EnableBtn.Caption := 'Enable';
    MainForm.EnableBtn.ImageIndex := 2;
  end
  else
  begin
    MainForm.EnableBtn.Caption := 'Diasble';
    MainForm.EnableBtn.ImageIndex := 3;
  end;
end;

//Вывод IsActive
procedure ShowStatus.ShowIsActive;
begin
  MainForm.ActiveLabel.Caption := Trim(Result[0]);
end;

//Вывод списка устройств
procedure ShowStatus.ShowDevices;
begin
  MainForm.LogMemo.Lines.Assign(Result);
end;

end.

