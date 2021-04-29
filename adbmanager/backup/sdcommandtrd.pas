unit SDCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  StartSDCommand = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    procedure ShowSDLog;
    procedure StopProgress;
    procedure StartProgress;

  end;

implementation

uses SDCardManager;

{ TRD }

//Вывод лога и прогресса
procedure StartSDCommand.Execute;
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
    ExProcess.Parameters.Add(sdcmd);

    ExProcess.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut]; //

    ExProcess.Execute;

    while ExProcess.Running do
    begin
      S.LoadFromStream(ExProcess.Output);
      //Выводим лог
      S.Text := Trim(S.Text);

      //sleep(100);
      if S.Count <> 0 then
        Synchronize(@ShowSDLog);
    end;

  finally
    Synchronize(@StopProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

procedure StartSDCommand.ShowSDLog;
var
  i: integer;
begin
  //Вывод построчно
  for i := 0 to S.Count - 1 do
    SDForm.SDMemo.Lines.Append(S[i]);
  //  SDForm.SDMemo.Lines.Assign(S);
end;


//Старт индикатора
procedure StartSDCommand.StartProgress;
begin
  //Метка отмены копирования
  SDForm.Panel4.Caption := SCancelCopyng;
  SDForm.SDMemo.Clear;
  SDForm.ProgressBar1.Style := pbstMarquee;
  SDForm.ProgressBar1.Visible := True;
end;

//Стоп индикатора
procedure StartSDCommand.StopProgress;
begin
  with SDForm do
  begin
    //Метка отмены копирования
    Panel4.Caption := '';

    //Обновление каталогов назначения (выборочно)
    if left_panel then
      CompDirUpdate
    else
      StartLS;

    ProgressBar1.Style := pbstNormal;
  end;
end;

end.
