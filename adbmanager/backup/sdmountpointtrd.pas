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
  try
    if Terminated then Exit;
    Synchronize(@StartProgress);

    FreeOnTerminate := True; // уничтожить по завершении

    if Terminated then Exit;
    S := TStringList.Create;
    ExProcess := TProcess.Create(nil);

    if Terminated then Exit;
    // Наполняем возможными точками монтирования SD-Card
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
      Add('/chroot/mnt/XVMbox/extcard0/');
      Add('/chroot/mnt/XVMbox/extcard1/');
      Add('/chroot/mnt/XVMbox/extcard2/');
    end;

    if Terminated then Exit;

    // Если устройство подключено
    if (MainForm.DevSheet.Caption <> SNoDevice) and
      (Pos('offline', MainForm.DevSheet.Caption) = 0) then
    begin
      if Terminated then Exit;
      // Получаем каталоги /storage/*
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add('adb shell ls /storage | grep -Ev "emul*|self"');
      ExProcess.Options := [poUsePipes, poWaitOnExit];
      ExProcess.Execute;
      if Terminated then Exit;
      S.LoadFromStream(ExProcess.Output);

      if Terminated then Exit;
      // Если нет в списке SDMountPoint - добавить из /storage/*
      if S.Count <> 0 then
        for i := 0 to S.Count - 1 do
          if SDMountPoint.IndexOf('/storage/' + Trim(S[i]) + '/') = -1 then
            SDMountPoint.Append('/storage/' + Trim(S[i]) + '/');

      if Terminated then Exit;
      // Проверить все точки на открытие/существование, несуществующие - удалить
      for i := SDMountPoint.Count - 1 downto 0 do
      begin
        if Terminated then Exit;
        ExProcess.Parameters.Delete(1);
        ExProcess.Parameters.Add('adb shell ' + '''' + 'cd ' +
          SDMountPoint[i] + ' &> /dev/null && echo "yes" || echo "no"' + '''');
        ExProcess.Execute;
        if Terminated then Exit;
        S.LoadFromStream(ExProcess.Output);
        if S.Count > 0 then
          if S[0] = 'no' then
            SDMountPoint.Delete(i);
      end;
    end;
  finally
    if not Terminated then
      Synchronize(@StopProgress);

    S.Free;
    ExProcess.Free;
    //   Terminate;
  end;
end;

{ БЛОК ЗАВЕРШЕНИЯ }

//Старт процедуры
procedure ReadSDMountPoint.StartProgress;
begin
  if Assigned(SDForm) then
  begin
    Screen.cursor := crHourGlass;
    SDForm.SDChangeBtn.Enabled := False;
  end;
end;

//Стоп процедуры
procedure ReadSDMountPoint.StopProgress;
begin
  if Assigned(SDForm) then
  begin
    if SDMountPoint.Count <> 0 then
    begin
      //Заголовок на первую существующую точку монтирования, если не открывалась ранее
      if SDMountPoint.IndexOf(SDForm.GroupBox2.Caption) = -1 then
        SDForm.GroupBox2.Caption := SDMountPoint[0];
      SDForm.SDChangeBtn.Enabled := True;
    end
    else
      //Если список точек монтирования пуст
    begin
      SDForm.GroupBox2.Caption := '/sdcard/';
      SDForm.SDChangeBtn.Enabled := False;
    end;

    Screen.cursor := crDefault;

    //Перечитываем точку монтирования
    SDForm.StartLS;
  end;
end;


end.
