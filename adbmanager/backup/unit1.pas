unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process, LCLTranslator, DefaultTranslator,
  ExtDlgs;

type

  { TMainForm }

  TMainForm = class(TForm)
    ActiveLabel: TLabel;
    DevicesBox: TListBox;
    EnabledLabel: TLabel;
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
    SaveDialog1: TSaveDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    StaticText1: TStaticText;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    ToolBar1: TToolBar;
    EnableBtn: TToolButton;
    DeleteKeyBtn: TToolButton;
    ToolBar2: TToolBar;
    InstallBtn: TToolButton;
    RestoreBtn: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ScreenShotBtn: TToolButton;
    RebootBtn: TToolButton;
    ToolButton15: TToolButton;
    ApkInfoBtn: TToolButton;
    ToolButton17: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    RestartBtn: TToolButton;
    StopBtn: TToolButton;
    UninstallBtn: TToolButton;
    ToolButton6: TToolButton;
    BackupBtn: TToolButton;
    ToolButton8: TToolButton;
    ExitBtn: TToolButton;
    ToolButton9: TToolButton;
    procedure ApkInfoBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActiveLabelChangeBounds(Sender: TObject);
    procedure EnabledLabelChangeBounds(Sender: TObject);
    procedure KeyLabelChangeBounds(Sender: TObject);
    procedure DisableBtnClick(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
  private

  public

  end;

var //Команда ADB
  adbcmd: string;

resourcestring
  SDisable = 'Disable';
  SEnable = 'Enable';
  SRebootMsg = 'Reboot selected smartphone?';
  SQueryCaption = 'Deleting a package';
  SPackageName = 'Input the package name:';

var
  MainForm: TMainForm;

implementation

uses ShowStatusTRD, ADBCommandTRD;

{$R *.lfm}

{ TMainForm }

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

procedure TMainForm.FormCreate(Sender: TObject);
var
  FStartShowStatusThread: TThread;
begin
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
  FADBCommandThread: TThread;
begin
  S := '';
  PageControl1.ActivePageIndex := 1;

  //Определяем команду по кнопке
  case (Sender as TToolButton).Tag of
    0: //apk-info (инфа о пакетах для удаления)
      adbcmd := 'adb shell pm list packages';

    1: //install
    begin
      OpenDialog1.Filter := 'APK-Package files (*.akp)|*.apk';
      if OpenDialog1.Execute then
        adbcmd := 'adb install "' + OpenDialog1.FileName + '"'
      else
        Exit;
    end;

    2: //uninstall
      repeat
        if not InputQuery(SQueryCaption, SPackageName, S) then

          Exit
        else
          adbcmd := 'adb uninstall ' + S;
      until S <> '';

    3: //backup (-shared + карта памяти)
      if SaveDialog1.Execute then
        adbcmd := 'adb backup -apk -shared -nosystem -f "' + SaveDialog1.FileName + '"'
      else
        Exit;

    4: //restore
    begin
      OpenDialog1.Filter := 'ADB Backup files (*.ab)|*.ab';
      if OpenDialog1.Execute then
        adbcmd := 'adb restore "' + Opendialog1.FileName + '"'
      else
        Exit;
    end;

    5: //screenshot
      if SelectDirectoryDialog1.Execute then
      begin
        //Имя скриншота (сек + 1)
        S := Concat(FormatDateTime('dd-mm-yyyy_hh-nn-ss', Now), '.png');
        SetCurrentDir(SelectDirectoryDialog1.FileName);
        adbcmd :=
          'adb shell screencap -p /sdcard/' + S + '; adb pull /sdcard/' +
          S + '; adb shell rm /sdcard/' + S;
      end
      else
        Exit;

    6: //reboot
      if MessageDlg(SRebootMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        adbcmd := 'adb reboot'
      else
        Exit;
  end;

  //Запуск команды и потока отображения лога исполнения
  FADBCommandThread := StartADBCommand.Create(False);
  FADBCommandThread.Priority := tpNormal;
end;

//Индикация статуса цветом
procedure TMainForm.ActiveLabelChangeBounds(Sender: TObject);
begin
  if ActiveLabel.Caption = 'active' then
    ActiveLabel.Font.Color := clGreen
  else
    ActiveLabel.Font.Color := clRed;
end;

procedure TMainForm.EnabledLabelChangeBounds(Sender: TObject);
begin
  if EnabledLabel.Caption = 'enabled' then
    EnabledLabel.Font.Color := clGreen
  else
    EnabledLabel.Font.Color := clRed;
end;

procedure TMainForm.KeyLabelChangeBounds(Sender: TObject);
begin
  if KeyLabel.Caption = 'yes' then
    KeyLabel.Font.Color := clGreen
  else
    KeyLabel.Font.Color := clRed;
end;

procedure TMainForm.DisableBtnClick(Sender: TObject);
begin
  StartProcess('systemctl disable adb');
end;

//Обработка нажатия кнопок управления ADB
procedure TMainForm.RestartBtnClick(Sender: TObject);
begin
  PageControl1.ActivePageIndex := 0;

  case (Sender as TToolButton).Tag of
    0: StartProcess('killall adb; systemctl restart adb'); //Start
    1: //Stop
    begin
      ActiveLabel.Caption := 'stopping';
      StartProcess('systemctl stop adb');
    end;
    2: //Enable-Disable
    begin
      if EnabledLabel.Caption = 'enabled' then
        StartProcess('systemctl disable adb')
      else
        StartProcess('systemctl enable adb');
    end;
    3: StartProcess('rm -rf ~/.android/*');  //Delete Key
    4: Close;
  end;

end;

end.
