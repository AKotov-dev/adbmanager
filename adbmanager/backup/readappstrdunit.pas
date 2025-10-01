unit ReadAppsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process, Math;

type
  ReadAppsTRD = class(TThread)
  private
  protected
  var
    S: TStringList;

    procedure Execute; override;

    procedure ShowAppList;
    procedure StopRead;
    procedure StartRead;
  end;

implementation

uses CheckUnit;

  { TRD }

procedure ReadAppsTRD.Execute;
var
  ExProcess: TProcess;
  PIDExists: boolean;
  Attempts: integer;

  procedure RunCmd(const ACommand: string; AOutput: TStringList = nil);
  begin
    ExProcess := TProcess.Create(nil);
    try
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add(ACommand);
      ExProcess.Options := [poUsePipes, poWaitOnExit, poStderrToOutPut];
      ExProcess.Execute;
      if Assigned(AOutput) then
        AOutput.LoadFromStream(ExProcess.Output);
    finally
      ExProcess.Free;
    end;
  end;

begin
  try
    Synchronize(@StartRead);

    S := TStringList.Create;
    FreeOnTerminate := True;

    RunCmd('adb devices | grep -w "device"', S);
    if Trim(S.Text) = '' then Exit;

    //Проверка установлен ли пакет на смартфоне
    RunCmd('adb shell pm list packages | grep com.example.iconextractor', S);
    if Trim(S.Text) <> '' then
    begin
      // --- 1. Чистим каталог на компе (в смартфоне делает IconExtractor ---
      if Terminated then Exit;
      RunCmd('rm -rf ~/.adbmanager/icons');

      // --- 2. Запуск Activity ---
      if Terminated then Exit;
      RunCmd('adb shell am start -n com.example.iconextractor/.MainActivity');

      // --- 3. Ждём появления pid ---
      Attempts := 0;
      repeat
        RunCmd('adb shell pidof com.example.iconextractor', S);
        PIDExists := Trim(S.Text) <> '';
        if not PIDExists then Sleep(300);
        Inc(Attempts);
        if Terminated then Exit;
      until (PIDExists) or (Attempts > 20); // максимум ~6 секунд

      // --- 4. Ждём исчезновения pid ---
      Attempts := 0;
      repeat
        RunCmd('adb shell pidof com.example.iconextractor', S);
        PIDExists := Trim(S.Text) <> '';
        if PIDExists then Sleep(500);
        Inc(Attempts);
        if Terminated then Exit;
      until (not PIDExists) or (Attempts > 120); // максимум ~1 минута

      // --- 5. Копирование png на комп ---
      if Terminated then Exit;
      RunCmd('adb pull /storage/emulated/0/Pictures/IconExtractor/icons ~/.adbmanager/');

      // --- 6. Ресайз png ---
      if Terminated then Exit;
      RunCmd('mogrify -resize ' + IntToStr(CheckForm.DefaultIcon.Height) +
        'x' + IntToStr(CheckForm.DefaultIcon.Height) + ' ~/.adbmanager/icons/*.png');
    end;

    // --- 7. Список всех пакетов ---
    if Terminated then Exit;
    RunCmd('adb shell pm list packages | sort | cut -d":" -f2', S);
    S.Text := Trim(S.Text);
    if (S.Count > 0) and (not Terminated) then
      Synchronize(@ShowAppList);

    // --- 8. Список отключённых пакетов ---
    if Terminated then Exit;
    RunCmd('adb shell pm list packages -d | cut -d":" -f2', S);
    S.Text := Trim(S.Text);

  finally
    Synchronize(@StopRead);
    S.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СПИСКА ПРИЛОЖЕНИЙ }

procedure ReadAppsTRD.ShowAppList;
var
  hText, hIcon: integer;
begin
  CheckForm.AppListBox.Items.Assign(S);

  //Выравнивание и центрирование
  if CheckForm.AppListBox.Count <> 0 then
  begin
    hText := CheckForm.AppListBox.Canvas.TextHeight('Wy');
    hIcon := CheckForm.DefaultIcon.Height;
    CheckForm.AppListBox.ItemHeight := Max(hText, hIcon) + 4;
    CheckForm.AppListBox.ItemIndex := 0;
  end;
end;

//Старт
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

//Стоп
procedure ReadAppsTRD.StopRead;
var
  i: integer;
begin
  with CheckForm do
  begin
    for i := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Checked[i] := True;

    for i := 0 to S.Count - 1 do
      AppListBox.Checked[AppListBox.Items.IndexOf(S[i])] := False;

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
