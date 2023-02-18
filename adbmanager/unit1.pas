unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process, LCLTranslator, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ActiveLabel: TLabel;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    KeyLabel: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LogMemo: TMemo;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    ProgressBar1: TProgressBar;
    AppListBtn: TToolButton;
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StaticText1: TStaticText;
    DevSheet: TTabSheet;
    StaticText2: TStaticText;
    ToolBar1: TToolBar;
    DeleteKeyBtn: TToolButton;
    ToolBar2: TToolBar;
    InstallBtn: TToolButton;
    SearchBtn: TToolButton;
    ScreenShotBtn: TToolButton;
    RebootBtn: TToolButton;
    RestartBtn: TToolButton;
    ShellBtn: TToolButton;
    ConnectBtn: TToolButton;
    ToolButton4: TToolButton;
    UninstallBtn: TToolButton;
    ExitBtn: TToolButton;
    procedure ApkInfoBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActiveLabelChangeBounds(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure KeyLabelChangeBounds(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure ToolButton4Click(Sender: TObject);
    procedure StartADBCmd;
  private

  public

  end;

var //Команда ADB
  adbcmd: string;

resourcestring
  SRebootMsg = 'Reboot device?';
  SDeleteCaption = 'Deleting a package';
  SPackageName = 'Input the package name:';
  SSearchCaption = 'Search packages';
  SSearchString = 'Input search string or *';
  SNoDevice = 'no device';
  SYes = 'yes';
  SNo = 'no';
  SRestart = 'restart...';
  SLaunched = 'launched';
  SDeleteAPK = 'ATTENTION! BE CAREFUL!' + #13#10 + #13#10 +
    'Removing packages may disrupt the system!' + #13#10 + #13#10 +
    'Before deleting, ' + 'BE SURE TO MAKE A BACKUP!' + #13#10 +
    #13#10 + 'Delete selected applications?';

var
  MainForm: TMainForm;

implementation

uses ADBDeviceStatusTRD, ADBCommandTRD, RebootUnit, SDCardManager,
  EmulatorUnit, CheckUnit;

{$R *.lfm}

{ TMainForm }

//Запуск команды и потока отображения лога исполнения
procedure TMainForm.StartADBCmd;
var
  FADBCommandThread: TThread;
begin
  FADBCommandThread := StartADBCommand.Create(False);
  FADBCommandThread.Priority := tpNormal;
end;

//StartCommand
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    // ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.ToolButton4Click(Sender: TObject);
begin
  SDForm.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  FStartShowStatusThread: TThread;
begin
  //Перезапуск сервера, если не запущен (adb devices и сам сервер запускаются в потоке статуса)
  StartProcess('[[ $(ss -lt | grep 5037) ]] || (adb kill-server; killall adb)');

  //Запуск потока отображения статуса
  FStartShowStatusThread := ShowStatus.Create(False);
  FStartShowStatusThread.Priority := tpNormal;

  MainForm.Caption := Application.Title;

  if not DirectoryExists(GetUserDir + '.config') then
    MkDir(GetUserDir + '.config');
  IniPropStorage1.IniFileName := GetUserDir + '.config/adbmanager.conf';
end;

//Обработка кнопок панели "Управление Смартфоном"
procedure TMainForm.ApkInfoBtnClick(Sender: TObject);
var
  S: string;
begin
  S := '';

  //Определяем команду по кнопке
  case (Sender as TToolButton).ImageIndex of
    0: //Connect
    begin
      EmulatorForm := TEmulatorForm.Create(Application);
      EmulatorForm.ShowModal;
      //Показываем Подключение/Сканирование
      if EmulatorForm.ModalResult <> mrOk then
        Exit;
    end;

    1: //Search Package
    begin
      repeat
        if not InputQuery(SSearchCaption, SSearchString, S) then
          Exit
      until S <> '';

      if S = '*' then
        adbcmd := 'adb shell pm list packages | cut -f2 -d ":" | sort'
      else
        adbcmd := 'adb shell pm list packages | cut -f2 -d ":" | grep -i "' +
          Trim(S) + '"';
    end;

    2: //install
    begin
      OpenDialog1.Filter := 'Package files (*.apk)|*.apk';
      if OpenDialog1.Execute then
        adbcmd := 'adb install "' + OpenDialog1.FileName + '"'
      else
        Exit;
    end;

    3: //uninstall
      repeat
        if not InputQuery(SDeleteCaption, SPackageName, S) then
          Exit
        else
          adbcmd := 'adb uninstall ' + Trim(S);
      until S <> '';

    4: //Отключение/Удаление приложений
    begin
      CheckForm.ShowModal;
      Exit;
    end;

    5: //SD-FileManager
    begin
      SDForm.Show;
      Exit;
    end;

    6: //screenshot
      if SelectDirectoryDialog1.Execute then
      begin
        SetCurrentDir(SelectDirectoryDialog1.FileName);

        //Имя скриншота (сек + 1)
        S := Concat('screenshot-', FormatDateTime('dd-mm-yyyy_hh-nn-ss', Now), '.png');
        adbcmd :=
          'adb shell screencap -p /sdcard/' + S + ' && adb pull /sdcard/' +
          S + '&& adb shell rm /sdcard/' + S;
      end
      else
        Exit;

    7: //Терминал Android Shell
    begin
      StartProcess('sakura -t "Android Shell" -c 110 -r 36 -f 10 -x "adb shell"');
      Exit;
    end;

    8: //reboot
    begin
      RebootForm := TRebootForm.Create(Application);
      RebootForm.ShowModal; //Показываем варианты Reboot
      if RebootForm.ModalResult <> mrOk then
        Exit;
    end;
  end;

  //Запуск команды и потока отображения лога исполнения
  StartADBCmd;
end;

//Индикация статуса цветом
procedure TMainForm.ActiveLabelChangeBounds(Sender: TObject);
begin
  if ActiveLabel.Caption = SLaunched then
    ActiveLabel.Font.Color := clGreen
  else
    ActiveLabel.Font.Color := clRed;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  IniPropStorage1.Restore;
end;

procedure TMainForm.KeyLabelChangeBounds(Sender: TObject);
begin
  if KeyLabel.Caption = SYes then
    KeyLabel.Font.Color := clGreen
  else
    KeyLabel.Font.Color := clRed;
end;

//Обработка нажатия кнопок управления ADB
procedure TMainForm.RestartBtnClick(Sender: TObject);
begin
  //Очистка лога
  LogMemo.Clear;

  case (Sender as TToolButton).Tag of
    0: //Restart
    begin
      LogMemo.Clear;
      ActiveLabel.Caption := SRestart;
      StartProcess('killall adb; adb kill-server');
    end;

    1: //Delete Key
      StartProcess('rm -rf ~/.android/*');

    2: Close;
  end;

end;

end.
