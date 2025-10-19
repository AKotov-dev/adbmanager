unit XDGOpenTRD;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls, ComCtrls, Dialogs;

type
  TXDGOpenTRD = class(TThread)
  private
    FRemotePath: string;
    FTempFile: string;
    FErrorMsg: string;
    procedure ShowProgress;
    procedure HideProgress;
    procedure OpenFile;
    procedure ShowError;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARemotePath: string);
  end;

implementation

uses
  SDCardManager;

constructor TXDGOpenTRD.Create(const ARemotePath: string);
begin
  inherited Create(True); // создаём в Suspended
  FreeOnTerminate := True;
  FRemotePath := ARemotePath;
  Start;
end;

// Показать прогресс
procedure TXDGOpenTRD.ShowProgress;
begin
  //Метка отмены копирования
  SDForm.Panel4.Caption := SCancelCopyng;
  SDForm.ProgressBar1.Style := pbstMarquee;
  SDForm.ProgressBar1.Refresh;
end;

// Скрыть прогресс
procedure TXDGOpenTRD.HideProgress;
begin
    //Метка отмены копирования
  SDForm.Panel4.Caption := '';
  SDForm.ProgressBar1.Style := pbstNormal;
  SDForm.ProgressBar1.Refresh;
end;

// Показать ошибку
procedure TXDGOpenTRD.ShowError;
begin
  if FErrorMsg <> '' then
    MessageDlg(FErrorMsg, mtError, [mbOK], 0);
end;

// Запуск xdg-open (в GUI-потоке!)
procedure TXDGOpenTRD.OpenFile;
var
  Proc: TProcess;
begin
  Proc := TProcess.Create(nil);
  try
    Proc.Executable := 'xdg-open';
    Proc.Parameters.Add(FTempFile);
    Proc.Options := [poNoConsole]; // не ждём завершения
    Proc.Execute;
  finally
    Proc.Free;
  end;
end;

// Основной код потока
procedure TXDGOpenTRD.Execute;
var
  TempDir, Cmd: string;
  Proc: TProcess;
begin
  Synchronize(@ShowProgress);
  try
    // --- 1. Подкаталог для временных файлов ---
    TempDir := GetEnvironmentVariable('HOME') + '/.adbmanager/tmp';
    ForceDirectories(TempDir);

    // --- 2. Путь к целевому файлу ---
    FTempFile := TempDir + '/' + ExtractFileName(FRemotePath);

    // --- 3. Копирование файла с устройства через adb ---
    Cmd := Format('adb pull "%s" "%s"', [FRemotePath, FTempFile]);

    Proc := TProcess.Create(nil);
    try
      Proc.Executable := 'bash';
      Proc.Parameters.Add('-c');
      Proc.Parameters.Add(Cmd);
      Proc.Options := [poWaitOnExit, poUsePipes];
      Proc.Execute;

      // Проверим результат
      if Proc.ExitStatus <> 0 then
        FErrorMsg :=
          'Ошибка при копировании файла с устройства.';

    finally
      Proc.Free;
    end;

    // --- 4. Если всё ок — открыть файл через xdg-open (в GUI потоке) ---
    if FErrorMsg = '' then
      Synchronize(@OpenFile)
    else
      Synchronize(@ShowError);

  finally
    Synchronize(@HideProgress);
  end;
end;

end.
