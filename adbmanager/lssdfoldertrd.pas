unit LSSDFolderTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, Forms, Controls;

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
    procedure ShowProgress;
    procedure HideProgress;

  end;

var
  android7: boolean;

implementation


uses SDCardManager;

{ TRD }

//Апдейт текущего каталога SDBox
procedure StartLSSD.Execute;
var
  sd_card: string;
  ExProcess: TProcess;
begin
  try
    Synchronize(@ShowProgress);

    S := TStringList.Create;
    FreeOnTerminate := True; //Уничтожить по завершении
    //SD-Card
    sd_card := SDForm.IniPropStorage1.StoredValue['SDCard'];

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    //Ошибки не выводим, только список, ждём окончания потока
    ExProcess.Options := [poWaitOnExit, poUsePipes];

    //Размер SD-Card, использовано и свободно (работает во всех Android)
    ExProcess.Parameters.Add('adb shell df -h ' + sd_card +
      ' | tail -n1 | awk ' + '''' + '{ print $2, $3, $4 }' + '''');
    Exprocess.Execute;

    S.LoadFromStream(ExProcess.Output);
    S.Text := Trim(S.Text);

    //Если есть, что выводить и SD-Карта существует
    if S.Count <> 0 then
      Synchronize(@SDSizeUsedFree);

    //Определяем версию Android > 7
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('adb shell ls -p ' + sd_card);
    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    if Pos('Aborting', S[0]) <> 0 then
      android7 := False
    else
      android7 := True;

    //ls текущего каталога с заменой спецсимволов
    ExProcess.Parameters.Delete(1);
    if not android7 then
      ExProcess.Parameters.Add('adb shell ls -F ' + '''' +
        SDForm.DetoxName(SDForm.GroupBox2.Caption) + '''' + ' | sort -t "d" -k 1,1')
    else
      //Android > 7?
      ExProcess.Parameters.Add('a=$(adb shell ls -p ' + '''' +
        SDForm.DetoxName(SDForm.GroupBox2.Caption) + '''' +
        '); b=$(echo "$a" | grep "/"); c=$(echo "$a" | grep -v "/"); echo -e "$b\n$c"  | grep -v "^$"');

    ExProcess.Execute;
    S.LoadFromStream(ExProcess.Output);
    Synchronize(@UpdateSDBox);

  finally
    Synchronize(@HideProgress);
    S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

//Начало операции
procedure StartLSSD.ShowProgress;
begin
  Screen.cursor := crHourGlass;
end;

//Окончание операции
procedure StartLSSD.HideProgress;
begin
  //Очищаем команду для корректного "Esc"
  sdcmd := '';

  Screen.cursor := crDefault;
end;

//Общий размер SD-Card, использовано и осталось
procedure StartLSSD.SDSizeUsedFree;
begin
  //Разделяем три пришедших значения
  S.Delimiter := ' ';
  S.StrictDelimiter := True;
  S.DelimitedText := S[0];

  //Для Android 4.x
  if S[2] <> 'file' then
  begin
    SDForm.Label4.Caption := S[0];
    SDForm.Label5.Caption := S[1];
    SDForm.Label6.Caption := S[2];
  end
  else
  begin
    SDForm.Label4.Caption := '...';
    SDForm.Label5.Caption := '...';
    SDForm.Label6.Caption := '...';
  end;
end;

{ БЛОК ВЫВОДА LS в SDBox }
procedure StartLSSD.UpdateSDBox;
begin
  //Вывод обновленного списка
  SDForm.SDBox.Items.Assign(S);
  //Апдейт содержимого
  SDForm.SDBox.Refresh;

  //Фокусируем
  SDForm.SDBox.SetFocus;

  //Если список не пуст - курсор в "0"
  if SDForm.SDBox.Count <> 0 then
    SDForm.SDBox.ItemIndex := 0;
end;

end.
