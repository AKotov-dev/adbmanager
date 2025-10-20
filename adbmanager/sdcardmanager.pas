unit SDCardManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, ComCtrls, Buttons, Process, LCLType,
  XMLPropStorage, StrUtils;

type

  { TSDForm }

  TSDForm = class(TForm)
    CheckBox1: TCheckBox;
    CompDir: TShellTreeView;
    CopyFromPC: TSpeedButton;
    CopyFromSmartphone: TSpeedButton;
    DelBtn: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    MkDirBtn: TSpeedButton;
    MkPCDirBtn: TSpeedButton;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ProgressBar1: TProgressBar;
    RefreshBtn: TSpeedButton;
    SDBox: TListBox;
    Panel2: TPanel;
    SDChangeBtn: TSpeedButton;
    SDMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    XMLPropStorage1: TXMLPropStorage;
    procedure CheckBox1Change(Sender: TObject);
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromSmartphoneClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MkDirBtnClick(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SDChangeBtnClick(Sender: TObject);
    procedure SDMemoKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure SelectAllBtnClick(Sender: TObject);

    //апдейт текущей директории SDBox (смартфон)
    procedure StartLS;

    //апдейт текущей директории CompDir (компьютер)
    procedure CompDirUpdate;

    procedure UpBtnClick(Sender: TObject);

    //Отработка команд копирования с выводом в лог
    procedure StartCommand;

    //Отмена копирования
    procedure CancelCopy;

    //Запуск произвольных команд BASH
    procedure StartProcess(command: string);

    function DetoxName(N: string): string;

  private

  public

  end;

resourcestring
  SDelete = 'Delete selected objects?';
  SOverwriteObject = 'Overwrite existing objects?';
  SObjectExists = 'The folder already exists!';
  SCreateDir = 'Create directory';
  SInputName = 'Enter the name:';
  SCancelCopyng = 'Esc - cancel... ';
  SCloseQueryCopy = 'File copying started! Finish?';

var
  SDForm: TSDForm;
  //Команда ADB и флаг панели, которую нужно обновить
  sdcmd: string;
  left_panel, FormLoaded: boolean;
  //Список возможных точек монтирования SD-Card
  SDMountPoint: TStringList;


implementation

uses SDCommandTRD, Unit1, LSSDFolderTRD, SDMountPointTRD, xdgopentrd;

  {$R *.lfm}

  { TSDForm }

//Автозамена сецсимволов
function TSDForm.DetoxName(N: string): string;
begin
  //заранее исключаем экранирование
  Result := StringReplace(N, '\', '\\', [rfReplaceAll]);
  //Заменяем все остальные
  Result := StringReplace(Result, ' ', '\ ', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '\<', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '\>', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
  Result := StringReplace(Result, '|', '\|', [rfReplaceAll]);
  Result := StringReplace(Result, ':', '\:', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, '&', '\&', [rfReplaceAll]);
end;

//Асинхронный запуск вспомогательных команд
procedure TSDForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Исполнение команд/вывод лога (sdcmd)
procedure TSDForm.StartCommand;
begin
  StartSDCommand.Create(False);
end;

//ls в директории /sdcard/... (SDBox)
procedure TSDForm.StartLS;
begin
  StartLSSD.Create(False);
end;

//Апдейт текущей директории CompDir (ShellTreeView)
procedure TSDForm.CompDirUpdate;
var
  i: integer; //Абсолютный индекс выделенного
  d: string; //Выделенная директория
begin
  //Запоминаем позицию курсора
  i := CompDir.Selected.AbsoluteIndex;
  d := ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

  //Обновляем  выбранного родителя
  CompDir.Refresh(CompDir.Selected.Parent);
  //Возвращаем курсор на исходную
  CompDir.Path := d;
  CompDir.Select(CompDir.Items[i]);
  CompDir.SetFocus;
end;

//Отменяем долгое копирование по "Esc" и при закрытии
procedure TSDForm.CancelCopy;
begin
  // Убиваем все adb push, adb pull процессы одной командой
  StartProcess('pkill -f "adb push|adb pull"');
end;

//На уровень вверх
procedure TSDForm.UpBtnClick(Sender: TObject);
var
  i: integer;
begin
  //Чтобы не проскочить верхний уровень
  for i := 0 to SDMountPoint.Count - 1 do
    if GroupBox2.Caption = SDMountPoint[i] then Exit;

  for i := Length(GroupBox2.Caption) - 1 downto 1 do
    if GroupBox2.Caption[i] = '/' then
    begin
      GroupBox2.Caption := Copy(GroupBox2.Caption, 1, i);
      //Перечитываем текущий каталог SDBox (GroupBox2.Caption)
      StartLS;

      break;
    end;
end;

//Отмена копирования = "Esc"; На уровень вверх = "BackSpace"
procedure TSDForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: CancelCopy;
    VK_BACK: UpBtn.Click;
    VK_F12: SDChangeBtn.Click;
  end;
end;

//Сплиттер 1/2 width, вывод команды - 1/7 height
procedure TSDForm.FormResize(Sender: TObject);
begin
  GroupBox1.Width := SDForm.Width div 2;
  Panel1.Height := SDForm.Height div 7;
end;

//Копирование с компа на SD-Card
procedure TSDForm.CopyFromPCClick(Sender: TObject);
var
  i, sd: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := False;

  c := '';
  //Флаг совпадения имени
  e := False;
  //Команда
  sdcmd := '';

  //Если выбрано и выбран не корень
  if (CompDir.Items.SelectionCount <> 0) and (not CompDir.Items.Item[0].Selected) then
  begin
    for i := 0 to CompDir.Items.Count - 1 do
    begin
      if CompDir.Items[i].Selected then
      begin
        //Ищем совпадения (перезапись объектов)
        if not e then
          for sd := 0 to SDBox.Count - 1 do
          begin
            if not android7 then
            begin
              if CompDir.Items[i].Text = Copy(SDBox.Items[sd], 3,
                Length(SDBox.Items[sd])) then
                e := True;
            end
            else
            begin
              if CompDir.Items[i].Text = ExcludeTrailingPathDelimiter(
                SDBox.Items[sd]) then
                e := True;
            end;
          end;

        c := 'adb push ' + '''' + ExcludeTrailingPathDelimiter(
          CompDir.Items[i].GetTextPath) + '''' + ' ' + '''' + GroupBox2.Caption + '''';

        sdcmd := c + '; ' + sdcmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCommand;
  end;
end;

//Копирование с SD-Card на комп
procedure TSDForm.CopyFromSmartphoneClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  //Флаг выбора панели
  left_panel := True;

  c := '';
  e := False; //Флаг совпадения файлов/папок (перезапись)
  sdcmd := '';  //Команда

  if SDBox.SelCount <> 0 then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if not android7 then
        begin
          if not e then
            if (FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
              ExtractFileName(GroupBox2.Caption +
              Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]))))) or
              (DirectoryExists(
              ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
              ExtractFileName(GroupBox2.Caption +
              Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]))))) then
              e := True;

          c := 'adb pull ' + '''' + GroupBox2.Caption +
            Copy(SDBox.Items[i], 3, Length(SDBox.Items[i])) + '''' +
            ' ' + '''' + ExtractFilePath(CompDir.GetPathFromNode(
            CompDir.Selected)) + '''';
        end
        else
        begin
          if not e then
            if (FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
              ExtractFileName(GroupBox2.Caption +
              ExcludeTrailingPathDelimiter(SDBox.Items[i])))) or
              (DirectoryExists(
              ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
              ExtractFileName(GroupBox2.Caption +
              ExcludeTrailingPathDelimiter(SDBox.Items[i])))) then
              e := True;

          c := 'adb pull ' + '''' + GroupBox2.Caption +
            ExcludeTrailingPathDelimiter(SDBox.Items[i]) + '''' +
            ' ' + '''' + ExtractFilePath(CompDir.GetPathFromNode(
            CompDir.Selected)) + '''';
        end;
        sdcmd := c + '; ' + sdcmd;
      end;
    end;

    //Если есть совпадения (перезапись файлов)
    if e and (MessageDlg(SOverwriteObject, mtConfirmation, [mbYes, mbNo], 0) <>
      mrYes) then
      exit;

    StartCommand;
  end;
end;

//Удаление объектов на SD-Card
procedure TSDForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команд...
begin
  //Команда в поток
  sdcmd := '';

  //Флаг выбора панели
  left_panel := False;

  //Удаление файлов и папок + содержащих спецсимволы
  if (SDBox.SelCount <> 0) and (MessageDlg(SDelete, mtConfirmation,
    [mbYes, mbNo], 0) = mrYes) then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if not android7 then
        begin
          if Copy(SDBox.Items[i], 1, 1) = 'd' then
            c := 'adb shell rm -rf ' + '''' + DetoxName(GroupBox2.Caption +
              Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]))) + ''''
          else
            c := 'adb shell rm -f ' + '''' + DetoxName(GroupBox2.Caption +
              Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]))) + '''';
        end
        else
        begin
          if Pos('/', SDBox.Items[i]) <> 0 then
            c := 'adb shell rm -rf ' + '''' + DetoxName(GroupBox2.Caption +
              SDBox.Items[i]) + ''''
          else
            c := 'adb shell rm -f ' + '''' + DetoxName(GroupBox2.Caption +
              SDBox.Items[i]) + '''';
        end;

        //Собираем команду
        sdcmd := c + '; ' + sdcmd;
      end;
    end;
    StartCommand;
  end;
end;

//Отмена копирования и очистка SDBox при закрытии формы
procedure TSDForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  try
    //For Plasma
    XMLPropStorage1.Save;

    CancelCopy;
    SDBox.Clear;

    //Очищаем лог
    SDMemo.Clear;

    //Обнуляем показания размера до перечитывания SD-Card
    Label4.Caption := '...';
    Label5.Caption := '...';
    Label6.Caption := '...';

    //Скрываем "Esc - отмена"
    Panel4.Caption := '';

  finally
    Screen.cursor := crDefault;
    //Освобождаем список точек монтирования SD-Card
    SDMountPoint.Free;
  end;
end;

//Отслеживание копирования при закрытии
procedure TSDForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  S: ansistring;
begin
  RunCommand('bash', ['-c', 'pgrep -f "adb pull|adb push"'], S);

  if Trim(S) <> '' then
    if MessageDlg(SCloseQueryCopy, mtConfirmation, [mbYes, mbCancel], 0) <> mrYes then
      Canclose := False
    else
      CanClose := True;
end;

procedure TSDForm.FormCreate(Sender: TObject);
begin
  XMLPropStorage1.FileName := MainForm.XMLPropStorage1.FileName;
end;

procedure TSDForm.FormShow(Sender: TObject);
{var
  FSDMountPointThread: TThread;}
begin
  //For Plasma
  XMLPropStorage1.Restore;

  FormLoaded := True;

  if CheckBox1.Checked then CompDir.ObjectTypes := [otFolders, otHidden, otNonFolders]
  else
    CompDir.ObjectTypes := [otFolders, otNonFolders];

  //Перечитываем корень CompDir (могли быть изменения на диске извне)
  RefreshBtn.Click;

  //Возвращаем сохраненную SD-Card (по умолчанию = /sdcard/ в IniPropStorage)
  //GroupBox2.Caption := IniPropStorage1.StoredValue['SDCard'];

  //Список возможных точек монтирования SD-Card
  SDMountPoint := TStringList.Create;

{  FSDMountPointThread := ReadSDMountPoint.Create(False);
  FSDMountPointThread.Priority := tpNormal;}

  ReadSDMountPoint.Create(False);
end;

procedure TSDForm.MkDirBtnClick(Sender: TObject);
var
  S: string;
begin
  //Флаг выбора панели
  left_panel := False;

  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  //DetoxName - Замена пробелов и спецсимволов
  sdcmd := 'adb shell mkdir ' + '''' + DetoxName(GroupBox2.Caption + S) + '''';

  StartCommand;
end;

//Создать каталог на SD-Card
procedure TSDForm.MkPCDirBtnClick(Sender: TObject);
var
  S: string;
begin
  //Флаг выбора панели
  left_panel := False;

  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  //Если есть совпадения (перезапись файлов)
  if DirectoryExists(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S) then
  begin
    MessageDlg(SObjectExists, mtWarning, [mbOK], 0);
    Exit;
  end;
  //Создаём директорию
  MkDir(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S);

  //Обновляем содержимое выделенного нода
  CompDirUpdate;
end;

//Перечитываем корень CompDir (могли быть изменения на диске извне)
procedure TSDForm.RefreshBtnClick(Sender: TObject);
begin
  with CompDir do
  begin
    Root := ExcludeTrailingPathDelimiter(GetUserDir);
    Items.Item[0].Selected := True;
    Select(CompDir.TopItem, [ssCtrl]);
    Refresh(CompDir.Selected.Parent);
    Select(CompDir.TopItem, [ssCtrl]);
    SetFocus;
  end;
end;

//Каталог вниз
procedure TSDForm.SDBoxDblClick(Sender: TObject);
var
  Ext, RemotePath: string;
begin
  if SDBox.Count <> 0 then
  begin
    //Если картинка - показать; путь на смартфоне
    if Android7 then
      RemotePath := GroupBox2.Caption + SDBox.Items[SDBox.ItemIndex]
    else
      RemotePAth := GroupBox2.Caption + Copy(SDBox.Items[SDBox.ItemIndex],
        3, Length(SDBox.Items[SDBox.ItemIndex]));

    // Проверка расширений
    Ext := LowerCase(ExtractFileExt(RemotePath));
    if MatchStr(Ext, ['.jpg', '.jpeg', '.png', '.bmp', '.webp', '.gif',
      '.heic', '.heif', '.tiff', '.mp4', '.mkv', '.avi', '.mov',
      '.webm', '.3gp', '.mp3', '.wav', '.ogg', '.flac', '.m4a', '.aac',
      '.pdf', '.txt', '.log', '.doc', '.docx', '.xls', '.xlsx', '.odp',
      '.ods', '.odt', '.rtf', '.csv', '.epub', '.zip', '.rar', '.7z',
      '.tar', '.gz', '.json', '.xml', '.html', '.vcf', '.url']) then
      TXDGOpenTRD.Create(RemotePath);

    if not android7 then //Android > 7?
    begin
      if Copy(SDBox.Items[SDBox.ItemIndex], 1, 1) = 'd' then
      begin
        GroupBox2.Caption := GroupBox2.Caption +
          Copy(SDBox.Items[SDBox.ItemIndex], 3,
          Length(SDBox.Items[SDBox.ItemIndex])) + '/';
        StartLS;
      end;
    end
    else
    begin
      if Pos('/', SDBox.Items[SDBox.ItemIndex]) <> 0 then
      begin
        GroupBox2.Caption := GroupBox2.Caption + SDBox.Items[SDBox.ItemIndex];
        StartLS;
      end;
    end;
  end;
end;

//Подстановка иконок папка/файл в ShellTreeView
procedure TSDForm.CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
begin
  if FileGetAttr(CompDir.GetPathFromNode(node)) and faDirectory <> 0 then
    Node.ImageIndex := 0
  else
    Node.ImageIndex := 1;
  Node.SelectedIndex := Node.ImageIndex;
end;

//Show hidden files and folders
procedure TSDForm.CheckBox1Change(Sender: TObject);
begin
  if FormLoaded then
  begin
    if CheckBox1.Checked then CompDir.ObjectTypes := [otFolders, otHidden, otNonFolders]
    else
      CompDir.ObjectTypes := [otFolders, otNonFolders];

    RefreshBtn.Click;
  end;
end;

//Перерисовка элементов списка ListBox
procedure TSDForm.SDBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
  ItemName: string;
  IconIndex: integer;
  TextWidth, TextHeight: integer;
  TextX, TextY, IconY, IconLeft: integer;
  DPI: integer;
  IconMargin, TextMargin: integer;
begin
  BitMap := TBitMap.Create;
  try
    DPI := Screen.PixelsPerInch;
    ItemName := SDBox.Items[Index];

    // Определяем тип элемента и удаляем служебные символы
    if not android7 then
    begin
      if Copy(ItemName, 1, 1) = 'd' then
      begin
        IconIndex := 0;
        Delete(ItemName, 1, 1);
      end
      else if Copy(ItemName, 1, 1) = '-' then
      begin
        IconIndex := 1;
        Delete(ItemName, 1, 1);
      end
      else
        IconIndex := 1;

      IconMargin := MulDiv(2, DPI, 96);   // меньший отступ иконки
      TextMargin := MulDiv(0, DPI, 96);
      // отступ текста от края иконки
    end
    else
    begin
      if Pos('/', ItemName) <> 0 then
      begin
        IconIndex := 0;
        Delete(ItemName, Length(ItemName), 1);
      end
      else
        IconIndex := 1;

      IconMargin := MulDiv(2, DPI, 96);   // чуть больше для android7
      TextMargin := MulDiv(4, DPI, 96);
      // текст подальше от иконки
    end;

    // Получаем иконку
    ImageList1.GetBitmap(IconIndex, BitMap);

    // Заливаем фон
    SDBox.Canvas.FillRect(ARect);

    // Размер текста
    TextWidth := SDBox.Canvas.TextWidth(ItemName);
    TextHeight := SDBox.Canvas.TextHeight(ItemName);

    // Вертикальное центрирование иконки
    IconY := ARect.Top + (ARect.Height - BitMap.Height) div 2;

    // Горизонтальное позиционирование
    IconLeft := ARect.Left + IconMargin;
    TextX := IconLeft + BitMap.Width + TextMargin;
    TextY := ARect.Top + (ARect.Height - TextHeight) div 2;

    // Рисуем иконку
    SDBox.Canvas.Draw(IconLeft, IconY, BitMap);

    // Рисуем текст
    SDBox.Canvas.TextOut(TextX, TextY, ItemName);

  finally
    BitMap.Free;
  end;
end;

//Выбор SD-Card
procedure TSDForm.SDChangeBtnClick(Sender: TObject);
begin
  SDBox.Clear;

  Label4.Caption := '...';
  Label5.Caption := '...';
  Label6.Caption := '...';

  //Возможные варианты SD-Card (учитываются UpBtn - верхний уровень)
  if SDMountPoint.IndexOf(GroupBox2.Caption) <> SDMountPoint.Count - 1 then
    GroupBox2.Caption := SDMountPoint[SDMountPoint.IndexOf(GroupBox2.Caption) + 1]
  else
    GroupBox2.Caption := SDMountPoint[0];

  //Запоминаем точку монтирования SD-Card
  XMLPropStorage1.Save;

  StartLS;
end;

//Исключаем нажатие клавиш в логе
procedure TSDForm.SDMemoKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  Key := $0;
end;

//Выделить всё
procedure TSDForm.SelectAllBtnClick(Sender: TObject);
begin
  SDBox.SelectAll;
end;

end.
