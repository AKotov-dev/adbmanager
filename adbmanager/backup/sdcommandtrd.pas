unit SDCommandTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process, Dialogs;

type
  TStartSDCommand = class(TThread)
  private
    FSdCmd: string;
    FLeftPanel: boolean;
    S: TStringList;
  protected
    procedure Execute; override;

    procedure ShowSDLog;
    procedure StopProgress;
    procedure StartProgress;
  public
    constructor Create(const ACmd: string; ALeftPanel: boolean);
  end;

implementation

uses SDCardManager;

{ Конструктор потока }
constructor TStartSDCommand.Create(const ACmd: string; ALeftPanel: boolean);
begin
  inherited Create(True); // True = поток создаётся в остановленном состоянии
  FreeOnTerminate := False;
  FSdCmd := ACmd;
  FLeftPanel := ALeftPanel;
end;

{ Основной метод Execute }
procedure TStartSDCommand.Execute;
var
  ExProcess: TProcess;
begin
  try
    Synchronize(@StartProgress);

    S := TStringList.Create;

    // Рабочий процесс
    ExProcess := TProcess.Create(nil);
    try
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add(FSdCmd);
      ExProcess.Options := [poUsePipes, poStderrToOutPut];

      ExProcess.Execute;

      while ExProcess.Running do
      begin
        S.LoadFromStream(ExProcess.Output);
        S.Text := Trim(S.Text);
        if S.Count <> 0 then
          Synchronize(@ShowSDLog);
      end;

    finally
      ExProcess.Free;
    end;

  finally
    Synchronize(@StopProgress);
    S.Free;
    Terminate;
  end;
end;

{ Вывод лога }
procedure TStartSDCommand.ShowSDLog;
var
  i: integer;
begin
  if Assigned(SDForm) then
    for i := 0 to S.Count - 1 do
      SDForm.SDMemo.Lines.Append(S[i]);
end;

{ Старт индикатора }
procedure TStartSDCommand.StartProgress;
begin
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
  if Assigned(SDForm) then
    with SDForm do
    begin
      Panel4.Caption := '';
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Refresh;

      // Обновление каталогов
      if FLeftPanel then ShowMessage('LEFT') else showmessage('RIGHT');

      if FLeftPanel then
        CompDirUpdate
      else
        StartLS;
    end;
end;

end.

