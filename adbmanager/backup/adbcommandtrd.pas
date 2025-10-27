unit ADBCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls;

type
  StartADBCommand = class(TThread)
  private
    FAdbCmd: string;          // Каждому потоку своя команда
    FTempLine: string;
    // Строка для передачи в ShowTempLine через Synchronize
    procedure StartProgress;
    procedure StopProgress;
    procedure ShowLog;
  protected
    procedure Execute; override;
  public
    constructor Create(const aCmd: string);
  end;

implementation

uses
  Unit1;

{ === Constructor === }
constructor StartADBCommand.Create(const aCmd: string);
begin
  inherited Create(False); // сразу старт
  FreeOnTerminate := True;
  FAdbCmd := aCmd;
end;

{ === Execute === }
procedure StartADBCommand.Execute;
var
  ExProcess: TProcess;
  Buf: array[0..1023] of ansichar;
  Len: longint;
  Acc: ansistring;
  LinePos: integer;
  S: string;
begin
  Synchronize(@StartProgress);
  Acc := '';

  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(FAdbCmd);
    ExProcess.Options := [poUsePipes, poStderrToOutPut];

    ExProcess.Execute;

    while ExProcess.Running or (ExProcess.Output.NumBytesAvailable > 0) do
    begin
      Len := ExProcess.Output.NumBytesAvailable;
      if Len > 0 then
      begin
        if Len > SizeOf(Buf) then Len := SizeOf(Buf);
        ExProcess.Output.Read(Buf, Len);
        Acc := Acc + Copy(Buf, 0, Len);
        // аккумулируем байты в строку

        // Разбиваем на строки по LineEnding
        LinePos := Pos(LineEnding, string(Acc));
        while LinePos > 0 do
        begin
          S := Copy(Acc, 1, LinePos - 1);
          FTempLine := S;
          Synchronize(@ShowTempLine); // добавляем строку в Memo
          Delete(Acc, 1, LinePos + Length(LineEnding) - 1);
          LinePos := Pos(LineEnding, string(Acc));
        end;
      end;
      Sleep(10);
    end;

    // Вывод остатка
    if Acc <> '' then
    begin
      FTempLine := string(Acc);
      Synchronize(@ShowLog);
    end;

  finally
    ExProcess.Free;
    Synchronize(@StopProgress);
  end;
end;

{ === GUI Helpers === }
procedure StartADBCommand.StartProgress;
begin
  if Assigned(MainForm) then
  begin
    MainForm.LogMemo.Clear;
    MainForm.ProgressBar1.Style := pbstMarquee;
    MainForm.ProgressBar1.Visible := True;
    MainForm.ProgressBar1.Refresh;
  end;
end;

procedure StartADBCommand.StopProgress;
begin
  if Assigned(MainForm) then
  begin
    MainForm.ProgressBar1.Visible := False;
    MainForm.ProgressBar1.Style := pbstNormal;
    MainForm.ProgressBar1.Refresh;
  end;
end;

procedure StartADBCommand.ShowTempLine;
begin
  if Assigned(MainForm) then
    MainForm.LogMemo.Lines.Append(FTempLine);
end;

end.
