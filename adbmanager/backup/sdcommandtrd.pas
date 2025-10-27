unit SDCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

type
  TStartSDCommand = class(TThread)
  private
    FSdCmd: string;
    FLeftPanel: boolean;
    //    S: TStringList;
    FTempLine: string;
    // Строка для передачи в ShowTempLine через Synchronize
  protected
    procedure Execute; override;

    procedure ShowTempLine;
    procedure StopProgress;
    procedure StartProgress;
  public
    constructor Create(const ACmd: string; ALeftPanel: boolean);
  end;

implementation

uses Unit1, SDCardManager;

{ Конструктор потока }
constructor TStartSDCommand.Create(const ACmd: string; ALeftPanel: boolean);
begin
  inherited Create(True);
  // True = поток создаётся в остановленном состоянии
  FreeOnTerminate := False;
  FSdCmd := ACmd;
  FLeftPanel := ALeftPanel;
end;

{ Основной метод Execute }
procedure TStartSDCommand.Execute;
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
    ExProcess.Parameters.Add(FSDCmd);
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
      Synchronize(@ShowTempLine);
    end;

  finally
    ExProcess.Free;
    Synchronize(@StopProgress);
  end;
end;

{ Вывод лога }
procedure TStartSDCommand.ShowTempLine;
begin
  if Assigned(SDForm) then
    SDForm.SDMemo.Lines.Append(FTempLine);
end;

{ Старт индикатора }
procedure TStartSDCommand.StartProgress;
begin
  MainForm.SDCardBtn.Enabled := False;
  if Assigned(SDForm) then
    with SDForm do
    begin
      Panel4.Caption := SCancelCopyng;
      SDMemo.Clear;
      ProgressBar1.Style := pbstMarquee;
      ProgressBar1.Refresh;
    end;
end;

{ Стоп индикатора }
procedure TStartSDCommand.StopProgress;
begin
  MainForm.SDCardBtn.Enabled := True;
  if Assigned(SDForm) then
    with SDForm do
    begin
      Panel4.Caption := '';
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Refresh;

      if FLeftPanel then
        CompDirUpdate
      else
        StartLS;
    end;
end;

end.
