unit ShowImageThread;
//Показываем картинку (используем пакет imagemagick)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls, LCLIntf, ComCtrls, Dialogs;

type
  TShowImageThread = class(TThread)
  private
    FRemotePath: string;
    FScale: integer;
    FErrorMessage: string;
    procedure ShowProgress;
    procedure HideProgress;
    procedure ShowError;
  protected
    procedure Execute; override;
  public
    constructor Create(const ARemotePath: string; AScale: integer);
  end;

implementation

uses
  SDCardManager, Unit1; // для SDForm и Screen.Width/Height

constructor TShowImageThread.Create(const ARemotePath: string; AScale: integer);
begin
  inherited Create(True); // создаём в Suspended
  FreeOnTerminate := True;
  FRemotePath := ARemotePath;
  FScale := AScale;
  Start;
end;

//Показываем прогресс
procedure TShowImageThread.ShowProgress;
begin
  SDForm.ProgressBar1.Style := pbstMarquee;
  SDForm.ProgressBar1.Refresh;
end;

//Останавливаем прогресс
procedure TShowImageThread.HideProgress;
begin
  SDForm.ProgressBar1.Style := pbstNormal;
  SDForm.ProgressBar1.Refresh;
end;

//Показываем ошибку, если файл битый
procedure TShowImageThread.ShowError;
begin
  MessageDlg(FErrorMessage, mtError, [mbOK], 0);
end;

//Запуск показа картинки
procedure TShowImageThread.Execute;
var
  ScreenW, ScreenH, W, H: integer;
  Title, Cmd, TempFile: string;
  Proc: TProcess;
begin
  Synchronize(@ShowProgress);
  try
    ScreenW := Screen.Width;
    ScreenH := Screen.Height;

    W := (ScreenW * FScale) div 100;
    H := (ScreenH * FScale) div 100;
    Title := ExtractFileName(FRemotePath);

    // временный файл в ~/.adbmanager
    TempFile := GetEnvironmentVariable('HOME') + '/.adbmanager/adb_image.jpg';

     // 1. Закрываем старый display, если есть
  RunCommand('pkill', ['-f', 'display'], Cmd);

    // конвейер: adb -> convert -> файл
    Cmd := Format(
      'adb exec-out cat "%s" | convert -auto-orient -resize %dx%d\> - "%s"',
      [FRemotePath, W, H, TempFile]);

    try
      Proc := TProcess.Create(nil);
      try
        Proc.Executable := 'bash';
        Proc.Parameters.Add('-c');
        Proc.Parameters.Add(Cmd);
        Proc.Options := [poNoConsole, poWaitOnExit];
        Proc.Execute;
        if Proc.ExitStatus <> 0 then
          raise Exception.Create(SImageOpenError);
      finally
        Proc.Free;
      end;

      // запускаем display асинхронно
      Proc := TProcess.Create(nil);
      try
        Proc.Executable := 'display';
        Proc.Parameters.Add('-title');
        Proc.Parameters.Add(Title);
        Proc.Parameters.Add(TempFile);
        Proc.Options := [poNoConsole, poDetached];
        Proc.Execute;
      finally
        Proc.Free;
      end;

    except
      on E: Exception do
      begin
        FErrorMessage := E.Message;
        Synchronize(@ShowError);
      end;
    end;

  finally
    Synchronize(@HideProgress);
  end;
end;

end.
