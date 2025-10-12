unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process, LCLTranslator, LCLType, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ActiveLabel: TLabel;
    Image1: TImage;
    ImageList1: TImageList;
    ImageList2: TImageList;
    IniPropStorage1: TIniPropStorage;
    KeyLabel: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelRAM: TLabel;
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
    ToolButton1: TToolButton;
    ToolButton4: TToolButton;
    UninstallBtn: TToolButton;
    ExitBtn: TToolButton;
    procedure ApkInfoBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure ActiveLabelChangeBounds(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure KeyLabelChangeBounds(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure StartProcess(command: string);

    procedure CreateInstallationScript;
  private

  public

  end;

  //var //Команда ADB
  //  adbcmd: string;

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
  SCloseQuery = 'Package installation started! Finish?';
  SDeleteAPK = 'ATTENTION! BE CAREFUL!' + #13#10 + #13#10 +
    'Removing packages may disrupt the system!' + #13#10 + #13#10 +
    'Before deleting, ' + 'BE SURE TO MAKE A BACKUP!' + #13#10 +
    #13#10 + 'Delete selected applications?';
  SErrorImageCopy = 'Error copying file from device!';
  SFileNotValid = 'The file does not match the current list of packages!';
  SADBNotFound = 'ADB not found!';

var
  MainForm: TMainForm;

implementation

uses ADBDeviceStatusTRD, ADBCommandTRD, RebootUnit, SDCardManager,
  EmulatorUnit, CheckUnit, Settings_Unit, UsingRAMTRD;

  {$R *.lfm}

  { TMainForm }

//Проверка установки ADB
function CheckADBInstalled(out Version: string): boolean;
begin
  Version := '';
  Result := RunCommand('adb', ['--version'], Version, [poWaitOnExit, poUsePipes]) and
    (Pos('Android Debug Bridge', Version) > 0);
  Version := Trim(Version);
end;

//Создать скрипт установки пакетов ~/.adbmanager/install_packages.sh
procedure TMainForm.CreateInstallationScript;
var
  S: TStringList;
begin
  //Если скрипт существует - выйти
  //if FileExists(GetUserDir + '.adbmanager/install_packages.sh') then Exit;

  try
    S := TStringList.Create;

    S.Add('#!/bin/bash');
    S.Add('');

    S.Add('set -e  # Exit on error');
    S.Add('');

    S.Add('# Проверка наличия подключенного устройства');
    S.Add('if [ $(adb devices | grep -c "device$") -eq 0 ]; then');
    S.Add('    echo "adb: no devices/emulators found"');
    S.Add('    exit 1');
    S.Add('fi');
    S.Add('');

  { S.Add('# Проверка, что процесс установки уже не запущен');
    S.Add('if pgrep -f "adb install" > /dev/null; then');
    S.Add('    echo "An installation process is already running. Please wait for it to finish."');
    S.Add('    exit 1');
    S.Add('fi');
    S.Add(''); }

    S.Add('if [ $# -lt 1 ]; then');
    S.Add('    echo "Usage: $0 file1.apk file2.xapk file3.apks ..."');
    S.Add('    exit 1');
    S.Add('fi');
    S.Add('');

    S.Add('ADB_CMD="adb"');
    S.Add('');

  { S.Add('# Check if /tmp exists, otherwise use $HOME/.adbmanager');
    S.Add('if [ ! -d "/tmp" ]; then');
    S.Add('    TEMP_BASE="$HOME/.adbmanager"');
    S.Add('else');
    S.Add('    TEMP_BASE="/tmp"');
    S.Add('fi');
    S.Add(''); }

    S.Add('# Check/Create $HOME/.adbmanager');
    S.Add('[ -d "$HOME/.adbmanager" ] || mkdir "$HOME/.adbmanager"');
    S.Add('TEMP_BASE="$HOME/.adbmanager"');
    S.Add('');

    S.Add('# Cleanup function on exit or interrupt (Ctrl+C)');
    S.Add('cleanup() {');
    S.Add('    echo "Cleaning up temporary files..."');
    S.Add('    rm -rf $TEMP_BASE/android_install_*');
    S.Add('}');
    S.Add('trap cleanup EXIT');
    S.Add('');

    S.Add('# Function to install a single APK');
    S.Add('install_apk() {');
    S.Add('    echo "Installing APK: $1 (Esc - Cancel)"');
    S.Add('    if ! "$ADB_CMD" install "$1"; then');
    S.Add('        echo "Installation failed for APK: $1"');
    S.Add('        exit 1  # Exit immediately if installation fails');
    S.Add('    fi');
    S.Add('}');
    S.Add('');

    S.Add('# Function to install multiple APKs (split APKs)');
    S.Add('install_multiple_apks() {');
    S.Add('    echo "Installing multiple APKs... (Esc - Cancel)"');
    S.Add('    if ! "$ADB_CMD" install-multiple "$1"/*.apk; then');
    S.Add('        echo "Installation failed for multiple APKs in: $1"');
    S.Add('        exit 1  # Exit immediately if installation fails');
    S.Add('    fi');
    S.Add('}');
    S.Add('');

    S.Add('# Function to move OBB files if they exist');
    S.Add('move_obb() {');
    S.Add('    local temp_dir="$1"');
    S.Add('    OBB_PATH=$(find "$temp_dir" -type d -name "obb" | head -n 1)');
    S.Add('    if [ -n "$OBB_PATH" ]; then');
    S.Add('        PKG_NAME=$("$ADB_CMD" shell pm list packages | grep -oP ' +
      '''' + 'package:\K\S+' + '''' + ' | head -n 1)');
    S.Add('        echo "Moving OBB files to /sdcard/Android/obb/$PKG_NAME/"');
    S.Add('        "$ADB_CMD" shell mkdir -p "/sdcard/Android/obb/$PKG_NAME/"');
    S.Add('        "$ADB_CMD" push "$OBB_PATH" "/sdcard/Android/obb/$PKG_NAME/"');
    S.Add('    fi');
    S.Add('}');
    S.Add('');

    S.Add('# Function to extract archives');
    S.Add('extract_archive() {');
    S.Add('    local file="$1"');
    S.Add('    local dest="$2"');
    S.Add('');

    S.Add('    echo "Extracting $file... (Esc - Cancel)"');
    S.Add('    7z x "$file" -o"$dest" -y &>/dev/null');
    S.Add('');

    S.Add('    # List extracted files for debugging');
    S.Add('    echo "Extracted files:"');
    S.Add('    find "$dest" -type f');
    S.Add('');

    S.Add('    if [ $? -ne 0 ]; then');
    S.Add('        echo "Failed to extract $file"');
    S.Add('        return 1');
    S.Add('    fi');
    S.Add('');

    S.Add('    return 0');
    S.Add('}');
    S.Add('');

    S.Add('# Process each file');
    S.Add('for FILE in "$@"; do');
    S.Add('    if [ ! -f "$FILE" ]; then');
    S.Add('        echo "File not found: $FILE"');
    S.Add('        continue');
    S.Add('    fi');
    S.Add('');

    S.Add('    EXT="${FILE##*.}"');
    S.Add('    TEMP_DIR="$TEMP_BASE/android_install_$(basename "$FILE" ."$EXT")"');
    S.Add('');

    S.Add('    # Clear temp directory before starting');
    S.Add('    rm -rf $TEMP_BASE/android_install_*');
    S.Add('');

    S.Add('    case "$EXT" in');
    S.Add('        apk)');
    S.Add('            install_apk "$FILE"');
    S.Add('            ;;');
    S.Add('        xapk|apks)');
    S.Add('            if extract_archive "$FILE" "$TEMP_DIR"; then');
    S.Add('                APK_COUNT=$(find "$TEMP_DIR" -type f -name "*.apk" | wc -l)');
    S.Add('                if [ "$APK_COUNT" -eq 1 ]; then');
    S.Add('                    install_apk "$TEMP_DIR"/*.apk');
    S.Add('                else');
    S.Add('                    install_multiple_apks "$TEMP_DIR"');
    S.Add('                fi');
    S.Add('                move_obb "$TEMP_DIR"');
    S.Add('            else');
    S.Add('                echo "Skipping $FILE due to extraction failure."');
    S.Add('                continue');
    S.Add('            fi');
    S.Add('            ;;');
    S.Add('        *)');
    S.Add('            echo "Unsupported file format: $FILE"');
    S.Add('            ;;');
    S.Add('    esac');
    S.Add('');

    S.Add('    # Remove temp files after installation, even if it failed');
    S.Add('    if [ -d "$TEMP_DIR" ]; then');
    S.Add('        echo "Removing temporary files..."');
    S.Add('        rm -rf $TEMP_BASE/android_install_*');
    S.Add('    fi');
    S.Add('done');
    S.Add('');

    S.Add('echo "Installation process completed."');

    S.SaveToFile(GetUserDir + '.adbmanager/install_packages.sh');
    StartProcess('chmod +x ' + GetUserDir + '.adbmanager/install_packages.sh');
  finally
    S.Free;
  end;
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

procedure TMainForm.FormCreate(Sender: TObject);
var
  bmp: TBitmap;
  ver: string;
begin
  //Устраняем баг иконки приложения (Lazarus-4.0)
  //https://gitlab.com/freepascal.org/lazarus/lazarus/-/issues/41636
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Assign(Image1.Picture.Graphic);
    Application.Icon.Assign(bmp);
  finally
    bmp.Free;
  end;

  //рабочая директория ~/.adbmanager
  if not DirectoryExists(GetUserDir + '.adbmanager') then
    MkDir(GetUserDir + '.adbmanager');
  //для файлов xdg-open
  if not DirectoryExists(GetUserDir + '.adbmanager/tmp') then
    MkDir(GetUserDir + '.adbmanager/tmp');

  {$IFDEF LCLQt6}
      MainForm.Caption := Application.Title + ' Qt';
  {$ELSE}
  MainForm.Caption := Application.Title;
  {$ENDIF}

  //ADB установлен?
  if CheckADBInstalled(Ver) then
  begin
    LogMemo.Append('ADB: ' + ver);
    //Перезапуск сервера, если не запущен (adb devices и сам сервер запускаются в потоке статуса)
    // StartProcess('if [ -z "$(ss -lt | grep 5037)" ]; then adb kill-server; killall adb; fi');
    //Запуск потока отображения памяти (RAM)
    TRAMThread.Create;
    //Запуск потока отображения статуса
    ShowStatus.Create(False);
  end
  else
    LogMemo.Append(SADBNotFound);
end;

//Обработка кнопок панели "Управление Смартфоном"
procedure TMainForm.ApkInfoBtnClick(Sender: TObject);
var
  i: integer;
  S, PackageNames, adbcmd: string;
begin
  S := '';
  adbcmd := '';
  PackageNames := '';

  //Определяем команду по кнопке
  case (Sender as TToolButton).ImageIndex of
    0: //Connect
    begin
      EmulatorForm := TEmulatorForm.Create(Application);
      EmulatorForm.ShowModal;
      //Показываем Подключение/Сканирование
      { if EmulatorForm.ModalResult <> mrOk then }
      Exit;
    end;

    1: //Search Package
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      //если adb выполняется - выйти
      if ProgressBar1.Style in [pbstMarquee] then Exit;

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
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      //если adb выполняется - выйти
      if ProgressBar1.Style in [pbstMarquee] then Exit;

      //Проверка/создание скрипта установки пакетов
      CreateInstallationScript;

      OpenDialog1.Filter := 'Package files (*.apk, *.apks, *.xapk)|*.apk;*.apks;*.xapk';
      if OpenDialog1.Execute then
      begin
        for i := 0 to OpenDialog1.Files.Count - 1 do
          PackageNames := PackageNames + ' "' + OpenDialog1.Files[i] + '"';

        adbcmd := GetUserDir + '.adbmanager/install_packages.sh ' + PackageNames;
      end
      else
        Exit;
    end;

    3: //uninstall
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      //если adb выполняется - выйти
      if (ProgressBar1.Style in [pbstMarquee]) then Exit;

      repeat
        if not InputQuery(SDeleteCaption, SPackageName, S) then
          Exit
        else
          adbcmd := 'adb uninstall ' + Trim(S);
      until S <> '';
    end;

    4: //Отключение/Удаление приложений
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      CheckForm.ShowModal;
      Exit;
    end;

    5: //SD-FileManager
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      SDForm.Show;
      Exit;
    end;

    6: //screenshot
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

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
    end;

    7: //Терминал Android Shell
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      //Выделяем имя устройства
      i := Pos(#9, DevSheet.Caption);
      StartProcess('sakura -t "Android Shell > ' + Trim(Copy(DevSheet.Caption, 1, i)) +
        '" -c 110 -r 36 -f 10 -x "adb shell"');
      Exit;
    end;

    8: //Токие настройки Android
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      SettingsForm.ShowModal;
      Exit;
    end;

    9: //reboot
    begin
      //Если устройства нет - Выход
      if DevSheet.Caption = sNoDevice then Exit;

      RebootForm := TRebootForm.Create(Application);
      RebootForm.ShowModal; //Показываем варианты Reboot
      //  if RebootForm.ModalResult <> mrOk then
      Exit;
    end;
  end;

  //Запуск команды и потока отображения лога исполнения
  StartADBCommand.Create(adbcmd);
end;

//Закрытие MainForm - завершение процессов
procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  SR: TSearchRec;
  TempDir: string;
begin
  // Очистить каталог временных файлов (xdg-open)
  TempDir := GetEnvironmentVariable('HOME') + '/.adbmanager/tmp';
  if FindFirst(TempDir + '/*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        DeleteFile(TempDir + '/' + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  //Аккуратное завершение копирования, если было запущено
  SDForm.CancelCopy;
end;

//Отслеживание процесса установки пакетов
procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  ScriptPID, ChildPIDs: ansistring;
begin
  CanClose := True;

  // Находим PID активного скрипта установки
  RunCommand('bash', ['-c', 'pgrep -f "install_packages.sh"'], ScriptPID);
  ScriptPID := Trim(ScriptPID);

  if ScriptPID <> '' then
  begin
    // Получаем всех дочерние процессы скрипта
    RunCommand('bash', ['-c', 'pgrep -P ' + ScriptPID], ChildPIDs);
    ChildPIDs := Trim(ChildPIDs);

    // Если есть активные дочерние процессы, спрашиваем пользователя
    if ChildPIDs <> '' then
    begin
      if MessageDlg(SCloseQuery, mtConfirmation, [mbYes, mbCancel], 0) = mrYes then
      begin
        // Завершаем все дочерние процессы скрипта
        RunCommand('bash', ['-c', 'pkill -P ' + ScriptPID], ChildPIDs);
        // Завершаем сам скрипт
        RunCommand('bash', ['-c', 'kill ' + ScriptPID], ChildPIDs);
        CanClose := True;
      end
      else
        CanClose := False;
    end;
  end;
end;

//Индикация статуса цветом
procedure TMainForm.ActiveLabelChangeBounds(Sender: TObject);
begin
  if ActiveLabel.Caption = SLaunched then
    ActiveLabel.Font.Color := clGreen
  else
    ActiveLabel.Font.Color := clRed;
end;

//Отмена установки пакетов по Esc
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    StartProcess(
      'pidof 7z && killall 7z; if pgrep -f "adb install" > /dev/null; then kill $(pgrep -f "adb install") >/dev/null 2>&1; fi');
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //For Plasma
  IniPropStorage1.IniFileName := GetUserDir + '.adbmanager/adbmanager.conf';
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
var
  ver: string;
begin
  case (Sender as TToolButton).Tag of
    0: //Restart
    begin
      ActiveLabel.Caption := SRestart;

      //ADB установлен?
      if CheckADBInstalled(ver) then
      begin
        LogMemo.Clear;
        LogMemo.Append('ADB: ' + ver);
        LabelRAM.Caption := 'RAM: 0.00 GB / 0.00 GB (0.0%)';
        StartProcess('killall -q adb; adb kill-server');
      end;
    end;

    1: //Delete Key
      StartProcess('rm -rf ~/.android/*');

    2: Close;
  end;

end;

end.
