unit LSSDFolderTRD;

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
    //Перечитываем текущую директорию SD-Card
    procedure UpdateSDBox;

  end;

implementation

uses SDCardManager;

{ TRD }

procedure StartLSSD.Execute;
var
  ExProcess: TProcess;
begin
  try
    S := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('adb shell ls -F ' + SDForm.GroupBox2.Caption +
      '| sort -t "d" -k 1,1');

    //Ошибки не выводим, только список
    ExProcess.Options := [poWaitOnExit, poUsePipes];

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    //S.Text := Trim(S.Text);

    //sleep(100);
    //if S.Count <> 0 then
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
  //Вывод обновленного списка
  SDForm.SDBox.Items.Assign(S);

  //Если список не пуст - курсор в "0"
  if SDForm.SDBox.Count <> 0 then
    SDForm.SDBox.ItemIndex := 0;
end;

end.
