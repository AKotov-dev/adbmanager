unit XDGOpenTRD;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls, ComCtrls, Dialogs;

type
  TXDGOpenTRD = class(TThread)
  private
    FRemotePath: string;
    procedure ShowProgress;
    procedure HideProgress;

  protected
    procedure Execute; override;
  public
    constructor Create(const ARemotePath: string);
  end;

implementation

uses
  SDCardManager, Unit1;

constructor TXDGOpenTRD.Create(const ARemotePath: string);
begin
  inherited Create(True); // создаём в Suspended
  FreeOnTerminate := True;
  FRemotePath := ARemotePath;
  Start;
end;

//Показываем прогресс
procedure TXDGOpenTRD.ShowProgress;
begin
  SDForm.ProgressBar1.Style := pbstMarquee;
  SDForm.ProgressBar1.Refresh;
end;

//Останавливаем прогресс
procedure TXDGOpenTRD.HideProgress;
begin
  SDForm.ProgressBar1.Style := pbstNormal;
  SDForm.ProgressBar1.Refresh;
end;

//Запуск приложений по mime-типу (xdg-open)
procedure TXDGOpenTRD.Execute;
var
  TempDir, TempFile, Cmd, S: string;
  SR: TSearchRec;
begin
  Synchronize(@ShowProgress);
  try
    // --- 1. Подкаталог для временных файлов ---
    TempDir := GetEnvironmentVariable('HOME') + '/.adbmanager/tmp';

    // Создать каталог, если не существует
    if not DirectoryExists(TempDir) then
      ForceDirectories(TempDir);

    // Очистить каталог
    if FindFirst(TempDir + '/*', faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
          DeleteFile(TempDir + '/' + SR.Name);
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;

    // --- 2. Подготовка временного файла ---
    TempFile := TempDir + '/' + ExtractFileName(FRemotePath);

    // --- 3. Копирование файла с устройства ---
    Cmd := Format('adb pull "%s" "%s"', [FRemotePath, TempFile]);
    if RunCommand('bash', ['-c', Cmd], S) = False then
    begin
      MessageDlg(SErrorImageCopy, mtError, [mbOK], 0);
      Exit;
    end;

    // --- 4. Открытие через xdg-open ---
    Cmd := Format('xdg-open "%s"', [TempFile]);
    RunCommand('bash', ['-c', Cmd], S);

  finally
    Synchronize(@HideProgress);
  end;
end;

end.
