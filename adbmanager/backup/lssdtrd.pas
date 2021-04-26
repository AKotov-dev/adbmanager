unit LSSDTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls;

type
  StartLSSD = class(TThread)
  private

    { Private declarations }
  protected
  var
    S: TStringList;

    procedure Execute; override;

    procedure UpdateSDBox;

  end;

implementation

uses SDCardManager;

{ TRD }

procedure StartLSSD.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса

    S := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('adb shell ls -F ' + SDForm.GroupBox2.Caption +
      '| sort -t "d" -k 1,1');

    ExProcess.Options := [poWaitOnExit, poUsePipes]; //Ошибки не выводим, только список

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    //Выводим содержимое директории
    S.Text := Trim(S.Text);

    //sleep(100);
    //  if S.Count <> 0 then
    Synchronize(@UpdateSDBox);

  finally
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ВЫВОДА LS в SDBox }

procedure StartLSSD.UpdateSDBox;
begin
  SDForm.SDBox.Items.Assign(S);
end;

end.
