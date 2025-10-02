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
  PIDExists: boolean;
  Attempts: integer;
begin
  try
    Synchronize(@StartRead);

    S := TStringList.Create;

    // --- Проверка устройства ---
    if Terminated then Exit;
    if not RunCmd('adb devices | grep -w "device"', S) then Exit;
    if Terminated or (Trim(S.Text) = '') then Exit;

    // --- Проверка пакета ---
    if not RunCmd('adb shell pm list packages | grep com.example.iconextractor', S) then
      Exit;
    if Terminated then Exit;

    if Trim(S.Text) <> '' then
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

    // --- Список пакетов ---
    if not RunCmd('adb shell pm list packages | sort | cut -d":" -f2', S) then Exit;
    if Terminated then Exit;
    S.Text := Trim(S.Text);

    if (S.Count > 0) and (not Terminated) then
      Synchronize(@ShowAppList);

    // --- Список отключённых пакетов ---
    if not RunCmd('adb shell pm list packages -d | cut -d":" -f2', S) then Exit;
    if Terminated then Exit;
    S.Text := Trim(S.Text);

  finally
    if (not Application.Terminated) and Assigned(CheckForm) and
      CheckForm.HandleAllocated then
      Synchronize(@StopRead);

    if Assigned(S) then
      S.Free;
  end;
end;

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
