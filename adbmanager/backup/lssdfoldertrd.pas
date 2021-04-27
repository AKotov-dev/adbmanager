unit LSSDFolderTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

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
    procedure SDSizeUsedFree;

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
    //ls с заменой пробелов
    ExProcess.Parameters.Add('adb shell ls -F "' +
      SDForm.DetoxName(SDForm.GroupBox2.Caption) + '" | sort -t "d" -k 1,1');

    //Ошибки не выводим, только список
    ExProcess.Options := [poWaitOnExit, poUsePipes];

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDBox);

    //Размер SD-Card, использовано и свободно
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell df /mnt/sdca1rd | tail -n1 | awk ' +
      '''' + '{ print $2, $3, $4 }' + '''');
    Exprocess.Execute;

    S.LoadFromStream(ExProcess.Output);
    S.Text := Trim(S.Text);

    //Если есть, что выводить и SD-Карта существует
    if (S.Count <> 0) and (Pos('No', S[0]) = 0) then
      Synchronize(@SDSizeUsedFree);

  finally
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Общий размер SD-Card, использовано и осталось
procedure StartLSSD.SDSizeUsedFree;
begin
  //Выделяем три значения раздельно
  S.Delimiter := ' ';
  S.StrictDelimiter := True;
  S.DelimitedText := S[0];

  SDForm.Label4.Caption := S[0];
  SDForm.Label5.Caption := S[1];
  SDForm.Label6.Caption := S[2];
end;

{ БЛОК ВЫВОДА LS в SDBox }
procedure StartLSSD.UpdateSDBox;
begin
  //Вывод обновленного списка
  SDForm.SDBox.Items.Assign(S);
  //Апдейт содержимого
  SDForm.SDBox.Update;

  //Если список не пуст - курсор в "0"
  if SDForm.SDBox.Count <> 0 then
    SDForm.SDBox.ItemIndex := 0;
end;

end.
