unit ADBCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls;

type
  StartADBCommand = class(TThread)
  private
    FAdbCmd: string;          // Каждому потоку своя команда
    ResultLog: TStringList;   // Лог потока
  protected
    procedure Execute; override;
    procedure ShowLog;
    procedure StartProgress;
    procedure StopProgress;
  public
    constructor Create(const aCmd: string);
  end;

implementation

uses Unit1;

{ === Constructor === }
constructor StartADBCommand.Create(const aCmd: string);
begin
  inherited Create(False); // сразу старт потока
  FreeOnTerminate := True;
  FAdbCmd := aCmd;
  ResultLog := TStringList.Create;
end;

{ === Execute === }
procedure StartADBCommand.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartProgress);

    ExProcess := TProcess.Create(nil);
    try
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add(FAdbCmd); // используем локальную переменную

      ExProcess.Options := [poUsePipes, poStderrToOutPut];

      ExProcess.Execute;

      while ExProcess.Running do
      begin
        ResultLog.LoadFromStream(ExProcess.Output);
        ResultLog.Text := Trim(ResultLog.Text);

        if ResultLog.Count <> 0 then
          Synchronize(@ShowLog);
      end;
    finally
      ExProcess.Free;
    end;

  finally
    Synchronize(@StopProgress);
    ResultLog.Free;
    Terminate;
  end;
end;

{ === Лог и прогресс === }
procedure StartADBCommand.StartProgress;
begin
  with MainForm do
  begin
    LogMemo.Clear;
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Visible := True;
    ProgressBar1.Refresh;
  end;
end;

procedure StartADBCommand.StopProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Refresh;
  end;
end;

procedure StartADBCommand.ShowLog;
var
  i: Integer;
begin
  for i := 0 to ResultLog.Count - 1 do
    MainForm.LogMemo.Lines.Append(ResultLog[i]);
end;

end.

