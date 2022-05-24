unit SDMountPointTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms, Controls;

type
  ReadSDMountPoint = class(TThread)
  private

    { Private declarations }
  protected

    procedure Execute; override;

    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1, SDCardManager;

{ TRD }

procedure ReadSDMountPoint.Execute;
var
  i: integer;
  S: TStringList;
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении

    S := TStringList.Create;
    ExProcess := TProcess.Create(nil);

    //Наполняем возможными точками монтирования SD-Card
    with SDMountPoint do
    begin
      Add('/sdcard/');
      Add('/mnt/sdcard0/');
      Add('/mnt/sdcard1/');
      Add('/mnt/sdcard2/');
      Add('/mnt/external/');
      Add('/mnt/external_sd/');
      Add('/mnt/sdcard/ext_sd/');
      Add('/mnt/sdcard/ext_sdcard/');
      Add('/mnt/sdcard/external_sd/');
      Add('/mnt/extSdCard/');
      Add('/storage/sdcard0/');
      Add('/storage/sdcard1/');
      Add('/storage/sdcard2/');
      Add('/storage/extSdCard/');
      Add('/storage/emulated/0/');
    end;

    //Если устройство подключено
    if (MainForm.DevSheet.Caption <> SNoDevice) and
      (Pos('offline', MainForm.DevSheet.Caption) = 0) then
    begin
      //Получаем каталоги /storage/*
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('adb shell ls /storage1 | grep -Ev "emul*|self"');
      ExProcess.Options := [poUsePipes, poWaitOnExit];
      ExProcess.Execute;
      S.LoadFromStream(ExProcess.Output);

      //Если нет в списке SDMountPoint - добавить из /storage/*
      if S.Count <> 0 then
        for i := 0 to S.Count - 1 do
          if SDMountPoint.IndexOf('/storage/' + Trim(S[i]) + '/') = -1 then
            SDMountPoint.Append('/storage/' + Trim(S[i]) + '/');

      //Проверить все на существование, несуществующие - удалить
      for i := SDMountPoint.Count - 1 downto 0 do
      begin
        ExProcess.Parameters.Delete(1);
        ExProcess.Parameters.Add('adb shell ' + '''' + '[ -d ' +
          SDMountPoint[i] + ' ] && echo "yes" || echo "no"' + '''');
        ExProcess.Execute;
        S.LoadFromStream(ExProcess.Output);
        if S[0] = 'no' then SDMountPoint.Delete(i);
      end;
    end;
  finally
    Synchronize(@StopProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;


{ БЛОК ЗАВЕРШЕНИЯ }

//Старт процедуры
procedure ReadSDMountPoint.StartProgress;
begin
  Screen.cursor := crHourGlass;
  SDForm.SDChangeBtn.Enabled := False;
end;

//Стоп процедуры
procedure ReadSDMountPoint.StopProgress;
begin
  Screen.cursor := crDefault;
  SDForm.SDChangeBtn.Enabled := True;
end;


end.
