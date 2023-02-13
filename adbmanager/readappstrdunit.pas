unit ReadAppsTRDUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  ReadAppsTRD = class(TThread)
  private

    { Private declarations }
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

//Вывод списка приложений для Включения/Отключения
procedure ReadAppsTRD.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartRead);

    S := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Options := [poUsePipes, poWaitOnExit]; //poWaitOnExit, poStderrToOutPut

    //Все приложения с сортировкой
    ExProcess.Parameters.Add('adb shell pm list packages | sort | cut -d":" -f2');

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    //Выводим список
    S.Text := Trim(S.Text);
    if S.Count <> 0 then
      Synchronize(@ShowAppList);

    //Читаем все неактивные приложения
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell pm list packages -d | cut -d":" -f2');
    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    //Отправляем для сравнения
    S.Text := Trim(S.Text);

  finally
    Synchronize(@StopRead);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ СПИСКА ПРИЛОЖЕНИЙ }

procedure ReadAppsTRD.ShowAppList;
begin
  CheckForm.AppListBox.Items.Assign(S);

  if CheckForm.AppListBox.Count <> 0 then
    CheckForm.AppListBox.ItemIndex := 0;
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
    //Отмечаем все чекбоксы
    for i := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Checked[i] := True;

    //Отключение неактивных приложений
    for i := 0 to S.Count - 1 do
      AppListBox.Checked[AppListBox.Items.IndexOf(S[i])] := False;

    //Сохраняем состояние items-чекбоксов в виртуальный список VList
    //Очищаем для повторного использования и начитываем заново
    VList.Clear;

    for i := 0 to AppListBox.Items.Count - 1 do
      if AppListBox.Checked[i] then VList.Add('1')
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
