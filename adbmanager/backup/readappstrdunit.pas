unit ReadAppsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process, Math;

type
  ReadAppsTRD = class(TThread)
  private
    S: TStringList;
    procedure ShowAppList;
    procedure StopRead;
    procedure StartRead;
    function RunCmd(const ACommand: string; AOutput: TStringList = nil): boolean;
  protected
    procedure Execute; override;
  end;

implementation

uses
  CheckUnit;

function ReadAppsTRD.RunCmd(const ACommand: string; AOutput: TStringList): boolean;
var
  ExProcess: TProcess;
begin
  Result := False;
  if Terminated then Exit;

  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(ACommand);
    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Execute;

    while ExProcess.Running do
    begin
      if Terminated then
      begin
        ExProcess.Terminate(0);
        Exit;
      end;
      Sleep(50);
    end;

    if Assigned(AOutput) then
      AOutput.LoadFromStream(ExProcess.Output);

    Result := True;
  finally
    ExProcess.Free;
  end;
end;

procedure ReadAppsTRD.Execute;
var
  AllPackages: TStringList;
  PIDExists: boolean;
  Attempts, i: integer;
begin
  try
    S := TStringList.Create;
    AllPackages := TStringList.Create;

    // --- Проверка устройства ---
    if Terminated then Exit;
    if not RunCmd('adb devices | grep -w "device"', S) then Exit;
    if Terminated or (Trim(S.Text) = '') then Exit;

    //Устройство подключено - Запуск индикатора
    Synchronize(@StartRead);

    // --- Получаем все пакеты один раз ---
    if Terminated then Exit;
    if not RunCmd('adb shell pm list packages', AllPackages) then Exit;
    if Terminated then Exit;

    // --- Проверка наличия пакета com.example.iconextractor ---
    if AllPackages.IndexOf('package:com.example.iconextractor') <> -1 then
    begin
      RunCmd('rm -rf ~/.adbmanager/icons');
      if Terminated then Exit;

      RunCmd('adb shell am start -n com.example.iconextractor/.MainActivity');
      if Terminated then Exit;

      // --- ждём появления pid ---
      Attempts := 0;
      repeat
        if not RunCmd('adb shell pidof com.example.iconextractor', S) then Exit;
        if Terminated then Exit;

        PIDExists := Trim(S.Text) <> '';
        if not PIDExists then Sleep(100);
        Inc(Attempts);
      until (PIDExists) or (Attempts > 20);

      if Terminated then Exit;

      // --- ждём исчезновения pid ---
      Attempts := 0;
      repeat
        if not RunCmd('adb shell pidof com.example.iconextractor', S) then Exit;
        if Terminated then Exit;

        PIDExists := Trim(S.Text) <> '';
        if PIDExists then Sleep(100);
        Inc(Attempts);
      until (not PIDExists) or (Attempts > 120);

      if Terminated then Exit;

      RunCmd('adb pull /storage/emulated/0/Pictures/IconExtractor/icons ~/.adbmanager/');
      if Terminated then Exit;

      RunCmd('gm mogrify -resize ' + IntToStr(CheckForm.DefaultIcon.Height) +
        'x' + IntToStr(CheckForm.DefaultIcon.Height) + ' ~/.adbmanager/icons/*.png');
      if Terminated then Exit;
    end;

    // --- Формируем список всех пакетов ---
    S.Clear;
    //Выделяем имена пакетов
    for i := 0 to AllPackages.Count - 1 do
      S.Add(Copy(AllPackages[i], Pos(':', AllPackages[i]) + 1, MaxInt));

    S.Text := Trim(S.Text);
    S.Sort;
    if (S.Count > 0) and (not Terminated) then
      Synchronize(@ShowAppList);

    // --- Список отключенных пакетов ---
    if not RunCmd('adb shell pm list packages -d', S) then Exit;
    if Terminated then Exit;
    S.Text := Trim(S.Text);
    //Выделяем имена пакетов
    for i := 0 to S.Count - 1 do
      S[i] := Copy(S[i], Pos(':', S[i]) + 1, MaxInt);
    //Для аккуратного снятия чекеров сверху вниз
    S.Sort;

  finally
    if (not Application.Terminated) and Assigned(CheckForm) and
      CheckForm.HandleAllocated then
      Synchronize(@StopRead);
    // гарантированная остановка прогресс-бара

    if Assigned(S) then
      S.Free;
    if Assigned(AllPackages) then
      AllPackages.Free;
  end;
end;

//Показываем список приложений
procedure ReadAppsTRD.ShowAppList;
var
  hText, hIcon: integer;
begin
  CheckForm.AppListBox.Items.Assign(S);
  CheckForm.AppListBox.Refresh;

  if CheckForm.AppListBox.Count <> 0 then
  begin
    hText := CheckForm.AppListBox.Canvas.TextHeight('Wy');
    hIcon := CheckForm.DefaultIcon.Height;
    CheckForm.AppListBox.ItemHeight := Max(hText, hIcon) + 4;
    CheckForm.AppListBox.ItemIndex := 0;
  end;
end;

//Стартуем прогресс
procedure ReadAppsTRD.StartRead;
begin
  with CheckForm do
  begin
    ModeBox.Enabled := False;
    ApplyBtn.Enabled := False;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Visible := True;
    ProgressBar1.Repaint;
  end;
end;

//Останов потока
procedure ReadAppsTRD.StopRead;
var
  i, j: integer;
begin
  with CheckForm do
  begin
    //Включаем галки всех пакетов
    for i := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Checked[i] := True;

    //Расставляем чекеры по списку отключенных пакетов
    if (S.Count > 0) then
    begin
      for i := 0 to S.Count - 1 do
      begin
        j := CheckForm.AppListBox.Items.IndexOf(S[i]);
        if j <> -1 then
          CheckForm.AppListBox.Checked[j] := False;
      end;
    end;

    //VList - снимок чекеров списка
    VList.Clear;
    for i := 0 to AppListBox.Items.Count - 1 do
      if AppListBox.Checked[i] then
        VList.Add('1')
      else
        VList.Add('0');

    ModeBox.Enabled := True;
    ApplyBtn.Enabled := True;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
    ProgressBar1.Repaint;
  end;
end;

end.
