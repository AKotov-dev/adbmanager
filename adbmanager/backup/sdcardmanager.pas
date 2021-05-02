unit SDCardManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, ComCtrls, Buttons, IniPropStorage, Process, LCLType;

type

  { TSDForm }

  TSDForm = class(TForm)
    VBtn: TSpeedButton;
    CompDir: TShellTreeView;
    CopyFromPC: TSpeedButton;
    CopyFromSmartphone: TSpeedButton;
    DelBtn: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
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
    SDMemo: TMemo;
    SelectAllBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure CompDirGetImageIndex(Sender: TObject; Node: TTreeNode);
    procedure CopyFromSmartphoneClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MkDirBtnClick(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
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

    function DetoxName(N: string): string;
    procedure VBtnClick(Sender: TObject);

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

var
  SDForm: TSDForm;
  //Команда ADB и флаг панели, которую нужно обновить
  sdcmd: string;
  left_panel: boolean;

implementation

uses SDCommandTRD, Unit1, LSSDFolderTRD;

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

//Версия просмотра Android 7.1+
procedure TSDForm.VBtnClick(Sender: TObject);
begin
  StartLS;
end;

//Исполнение команд/вывод лога (sdcmd)
procedure TSDForm.StartCommand;
var
  FSDCommandThread: TThread;
begin
  FSDCommandThread := StartSDCommand.Create(False);
  FSDCommandThread.Priority := tpNormal;
end;

//ls в директории /sdcard/... (SDBox)
procedure TSDForm.StartLS;
var
  FLSSDThread: TThread;
begin
  FLSSDThread := StartLSSD.Create(False);
  FLSSDThread.Priority := tpHighest; //tpHigher
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
  //Если копирование выполняется - отменяем
  if sdcmd <> '' then
  begin
    sdcmd := 'kill $(pgrep -f "/sdcard/")';
    StartCommand;
  end;
end;

//На уровень вверх
procedure TSDForm.UpBtnClick(Sender: TObject);
var
  i: integer;
begin
  if GroupBox2.Caption = '/sdcard/' then
    Exit;

  for i := Length(GroupBox2.Caption) - 1 downto 1 do
    if GroupBox2.Caption[i] = '/' then
    begin
      GroupBox2.Caption := Copy(GroupBox2.Caption, 1, i);
      //Перечитываем текущий каталог SDBox (GroupBox2.Caption)
      StartLS;

      break;
    end;
end;

//Домашний каталог - текущий
procedure TSDForm.FormCreate(Sender: TObject);
begin
  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

//Отмена копирования по "Esc"
procedure TSDForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    CancelCopy;
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
            if not SDForm.VBtn.Down then
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
        if not e then
          if not SDForm.VBtn.Down then
          begin
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
        if not SDForm.VBtn.Down then
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

//Отмена копирования при закрытии формы
procedure TSDForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CancelCopy;
end;

procedure TSDForm.FormShow(Sender: TObject);
begin
  //Перечитываем корень CompDir (могли быть изменения на диске извне)
  RefreshBtn.Click;

  //Очищаем лог
  SDMemo.Clear;

  //Обнуляем показания размера до перечитывания SD-Card
  Label4.Caption := '...';
  Label5.Caption := '...';
  Label6.Caption := '...';
  //Скрываем "Esc - отмена"
  Panel4.Caption := '';

  //Возвращаем и перечитываем исходную директорию SD-Card
  GroupBox2.Caption := '/sdcard/';
  StartLS;
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
    Select(CompDir.TopItem, [ssCtrl]);
    Refresh(CompDir.Selected.Parent);
    Select(CompDir.TopItem, [ssCtrl]);
    SetFocus;
  end;
end;

//Каталог вверх
procedure TSDForm.SDBoxDblClick(Sender: TObject);
begin
  if SDBox.Count <> 0 then
  begin
    if not SDForm.VBtn.Down then //Android > 7?
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

//Перерисовка элементов списка ShellTreeView
procedure TSDForm.SDBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  BitMap := TBitMap.Create;
  try
    ImageList1.GetBitMap(0, BitMap);

    with SDForm.SDBox do
    begin
      Canvas.FillRect(aRect);
      //Вывод текста со сдвигом (общий)
      // Canvas.TextOut(aRect.Left + 14, aRect.Top + 5, Items[Index]);
      if not SDForm.VBtn.Down then
      begin
        //Сверху иконки взависимости от первого символа
        if Copy(Items[Index], 1, 1) = 'd' then
        begin
          //Имя папки
          Canvas.TextOut(aRect.Left + 14, aRect.Top + 5, Items[Index]);
          //Иконка папки
          ImageList1.GetBitMap(0, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end
        else
        if Copy(Items[Index], 1, 1) = '-' then
        begin
          //Имя файла
          Canvas.TextOut(aRect.Left + 17, aRect.Top + 5, Items[Index]);
          //Иконка файла
          ImageList1.GetBitMap(1, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end;
      end
      else
      begin
        //Сверху иконки взависимости от последнего символа ('/')
        if Pos('/', Items[Index]) <> 0 then
        begin
          //Имя папки
          Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
          //Иконка папки
          ImageList1.GetBitMap(0, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end
        else
        begin
          //Имя файла
          Canvas.TextOut(aRect.Left + 27, aRect.Top + 5, Items[Index]);
          //Иконка файла
          ImageList1.GetBitMap(1, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end;
      end;
    end;
  finally
    BitMap.Free;
  end;
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
