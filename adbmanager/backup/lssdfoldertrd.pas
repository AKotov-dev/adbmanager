unit LSSDFolderTRD;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, ComCtrls, Process;

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

  //Версия Android подключенного устройства
var
  android7: boolean;

implementation

uses Unit1, SDCardManager;

  { TRD }

//Апдейт текущего каталога SDBox
procedure StartLSSD.Execute;
var
  ExProcess: TProcess;
begin
  try
    if Terminated then Exit;
    Synchronize(@ShowProgress);

    FreeOnTerminate := True; // уничтожить по завершении

    if Terminated then Exit;
    S := TStringList.Create;
    ExProcess := TProcess.Create(nil);

    if Terminated then Exit;
    // Если устройство подключено
    if (MainForm.DevSheet.Caption <> SNoDevice) and
      (Pos('offline', MainForm.DevSheet.Caption) = 0) then
    begin
      if Terminated then Exit;
      ExProcess.Executable := 'bash';
      ExProcess.Parameters.Add('-c');
      ExProcess.Options := [poWaitOnExit, poUsePipes];

      if Terminated then Exit;
      // Размер SD-Card, использовано и свободно
      ExProcess.Parameters.Add('adb shell df -h ' + SDForm.GroupBox2.Caption +
        ' | tail -n1 | awk ' + '''' + '{ print $2, $3, $4 }' + '''');
      ExProcess.Execute;
      if Terminated then Exit;
      S.LoadFromStream(ExProcess.Output);
      S.Text := Trim(S.Text);

      if Terminated then Exit;
      // Если есть что выводить и SD-Карта существует
      if S.Count <> 0 then
        Synchronize(@SDSizeUsedFree);

      if Terminated then Exit;
      // Определяем версию Android > 7
      ExProcess.Parameters.Delete(1);
      ExProcess.Parameters.Add('adb shell ls -p /');
      ExProcess.Execute;
      if Terminated then Exit;
      S.LoadFromStream(ExProcess.Output);
      if S.Count > 0 then
        if Pos('Aborting', S[0]) <> 0 then
          android7 := False
        else
          android7 := True;

      if Terminated then Exit;
      // ls текущего каталога с заменой спецсимволов
      ExProcess.Parameters.Delete(1);
      if not android7 then
        ExProcess.Parameters.Add('adb shell ls -a -F ' + '''' +
          SDForm.DetoxName(SDForm.GroupBox2.Caption) + '''' + ' | sort -t "d" -k 1,1')
      else
        ExProcess.Parameters.Add('a=$(adb shell ls -A -p ' + '''' +
          SDForm.DetoxName(SDForm.GroupBox2.Caption) + '''' +
          '); b=$(echo "$a" | grep "/"); c=$(echo "$a" | grep -v "/"); echo -e "$b\n$c"  | grep -v "^$"');

      ExProcess.Execute;
      if Terminated then Exit;
      S.LoadFromStream(ExProcess.Output);

      if Terminated then Exit;
      Synchronize(@UpdateSDBox);
    end;

  finally
    if not Terminated then
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
      SDForm.ProgressBar1.Style := pbstMarquee;
 //   ProgressBar1.Visible := True;
    SDForm.ProgressBar1.Repaint;
end;

//Окончание операции
procedure StartLSSD.HideProgress;
begin
  //Очищаем команду для корректного "Esc"
  sdcmd := '';

     SDForm.ProgressBar1.Style := pbstNormal;
   // ProgressBar1.Visible := True;
    SDForm.ProgressBar1.Repaint;

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
