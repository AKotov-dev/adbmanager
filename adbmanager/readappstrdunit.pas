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
    procedure StopProgress;
    procedure StartProgress;

  end;

implementation

uses CheckUnit;

{ TRD }

//Вывод списка и прогресса
procedure ReadAppsTRD.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartProgress);

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

    //Все неактивные приложения
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell pm list packages -d | cut -d":" -f2');
    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    //Отправляем для сравнения
    S.Text := Trim(S.Text);

  finally
    Synchronize(@StopProgress);
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
procedure ReadAppsTRD.StartProgress;
begin
 { CheckForm.Label2.Visible := True;
  CheckForm.Label2.Repaint;}
  with CheckForm do
  begin
    ProgressBar1.Visible := True;
    ProgressBar1.Repaint;
    ProgressBar1.Style := pbstMarquee;
  end;
end;

//Стоп
procedure ReadAppsTRD.StopProgress;
var
  i: integer;
begin
  with CheckForm do
  begin
    //Отмечаем все чекбоксы
    for i := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Checked[i] := True;

    //Отключение неактивных
    for i := 0 to S.Count - 1 do
      AppListBox.Checked[AppListBox.Items.IndexOf(S[i])] := False;

    //Сохраняем состояние чекбоксов в виртуальный список
    VList.Clear;
    for i := 0 to AppListBox.Items.Count - 1 do
      if AppListBox.Checked[i] then VList.Add('1')
      else
        VList.Add('0');

    ProgressBar1.Visible := False;
    ProgressBar1.Repaint;
    ProgressBar1.Style := pbstNormal;
  end;
end;

end.
