unit ADBCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Graphics;

type
  StartADBCommand = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartADBCommand.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожать по завершении
    Result := TStringList.Create;

    //Вывод лога и прогресса
    ExProcess := TProcess.Create(nil); //Рабочий процесс

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(adbcmd);

    ExProcess.Options := ExProcess.Options + [poUsePipes, poStderrToOutPut];

    ExProcess.Execute;

    //Пока поток запущен, отдавать результат выполнения в MainForm.Memo1
    while ExProcess.Running do
    begin
      Result.LoadFromStream(ExProcess.Output);
      //Выводим лог конвертирования
      if Result.Count <> 0 then
        Synchronize(@ShowLog);
    end;

  finally
    Synchronize(@StopProgress);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт индикатора
procedure StartADBCommand.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Visible := True;
  end;
end;

//Стоп индикатора
procedure StartADBCommand.StopProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Position := 0;
  end;
end;

//Вывод лога (построчное накопление)
procedure StartADBCommand.ShowLog;
begin
  if adbcmd <> 'adb shell pm list packages' then
  MainForm.LogMemo.Lines.Add(Trim(Result[0])) else
      MainForm.LogMemo.Lines.Assign(Result);
end;

end.

