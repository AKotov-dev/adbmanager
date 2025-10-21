unit CheckUnit;

{$mode ObjFPC}{$H+}

interface


uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CheckLst, StdCtrls,
  ComCtrls, Buttons, Types, LCLIntf, Menus, ReadAppsTrdUnit,
  ClipBrd, ExtCtrls, LCLType, IniFiles;

type

  { TCheckForm }

  TCheckForm = class(TForm)
    AppListBox: TCheckListBox;
    ApplyBtn: TButton;
    DefaultIcon: TImageList;
    CopyToClipboard: TMenuItem;
    LoadFromTXT: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SaveToFile: TMenuItem;
    Separator1: TMenuItem;
    ModeBox: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    PopupMenu1: TPopupMenu;
    ProgressBar1: TProgressBar;
    ClearBtn: TSpeedButton;
    PkgBtn: TSpeedButton;
    procedure AppListBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ApplyBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure CopyToClipboardClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LoadFromTXTClick(Sender: TObject);
    procedure ModeBoxChange(Sender: TObject);
    procedure PkgBtnClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure SaveToFileClick(Sender: TObject);
    procedure SetItemIndexSafely(Index: integer);
    procedure SetItemIndexFromQueue(Data: PtrInt);

    procedure DrawQt6Item(CLB: TCheckListBox; Index: integer; ARect: TRect;
      State: TOwnerDrawState);

    procedure DrawGTK2Item(CLB: TCheckListBox; Index: integer;
      ARect: TRect; State: TOwnerDrawState);

    procedure SaveSettings;
    procedure LoadSettings;

  private
    FReadThread: ReadAppsTRD;
  public
    VList: TStringList;
    procedure StartThread;
    procedure StopThread;
  end;

var
  CheckForm: TCheckForm;

implementation

uses Unit1, ADBCommandTRD;

  {$R *.lfm}

  { TCheckForm }


//Сохранение настроек формы
procedure TCheckForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(CONF);
  try
    Ini.WriteInteger('CheckForm', 'Top', CheckForm.Top);
    Ini.WriteInteger('CheckForm', 'Left', CheckForm.Left);
    Ini.WriteInteger('CheckForm', 'Width', CheckForm.Width);
    Ini.WriteInteger('CheckForm', 'Height', CheckForm.Height);
    Ini.WriteString('CheckForm', 'OpenDialog1', OpenDialog1.InitialDir);
    Ini.WriteString('CheckForm', 'SaveDialog1', SaveDialog1.InitialDir);
  finally
    Ini.Free;
  end;
end;

//Загрузка настроек формы
procedure TCheckForm.LoadSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(CONF) then Exit;
  Ini := TIniFile.Create(CONF);
  try
    CheckForm.Top := Ini.ReadInteger('CheckForm', 'Top', CheckForm.Top);
    CheckForm.Left := Ini.ReadInteger('CheckForm', 'Left', CheckForm.Left);
    CheckForm.Width := Ini.ReadInteger('CheckForm', 'Width', CheckForm.Width);
    CheckForm.Height := Ini.ReadInteger('CheckForm', 'Height', CheckForm.Height);

    OpenDialog1.InitialDir := Ini.ReadString('CheckForm', 'OpenDialog1',
      OpenDialog1.InitialDir);

    SaveDialog1.InitialDir := Ini.ReadString('CheckForm', 'SaveDialog1',
      SaveDialog1.InitialDir);
  finally
    Ini.Free;
  end;
end;

// --- Установка указателя в начало списка ---
procedure TCheckForm.SetItemIndexSafely(Index: integer);
begin
  // Снимаем фокус перед установкой
  AppListBox.TabStop := False;

  // Используем Application.QueueAsyncCall для отложенной установки ItemIndex
  Application.QueueAsyncCall(@SetItemIndexFromQueue, Index);
end;

procedure TCheckForm.SetItemIndexFromQueue(Data: PtrInt);
begin
  // Устанавливаем ItemIndex в главном потоке
  AppListBox.ItemIndex := Data;
  AppListBox.TabStop := True;  // Возвращаем фокус
end;

// ---

procedure TCheckForm.StopThread;
begin
  if Assigned(FReadThread) then
  begin
    FReadThread.Terminate;
    try
      FReadThread.WaitFor;   // ждём завершения
    except
      on E: Exception do
        ShowMessage('Ошибка завершения потока: ' + E.Message);
    end;
    FreeAndNil(FReadThread);
  end;
end;

procedure TCheckForm.StartThread;
begin
  if Assigned(FReadThread) and (not FReadThread.Finished) then Exit;

  FReadThread := ReadAppsTRD.Create(True);  // в Suspended
  FReadThread.FreeOnTerminate := False;     // освобождаем вручную
  FReadThread.Start;
end;

procedure TCheckForm.FormShow(Sender: TObject);
begin
  //For Plasma
  LoadSettings;

  AppListBox.Clear;
  Edit1.Clear;
  ModeBox.Checked := False;
  ClearBtn.Width := Edit1.Height;
  PkgBtn.Width := Edit1.Height;

  //Виртуальный список для сравнения чекбоксов (исходный)
  VList := TStringList.Create;

  //Запуск потока загрузки списка приложений
  StartThread;
end;

procedure SetItemIndexProc(ListBox: TCheckListBox; Index: integer);
begin
  ListBox.ItemIndex := Index;
  ListBox.TabStop := True; // Возвращаем фокус
end;

//Загрузка списка пакетов и состояний из файла
procedure TCheckForm.LoadFromTXTClick(Sender: TObject);
var
  Lines: TStringList;
  I: integer;
  Parts: TStringList;
  PackageName: string;
  State: boolean;
  AllValid: boolean;
begin
  if OpenDialog1.Execute then
  begin
    Lines := TStringList.Create;
    Parts := TStringList.Create;
    try
      Lines.LoadFromFile(OpenDialog1.FileName);
      Lines.Text := Trim(Lines.Text);
      AllValid := True;

      for I := 0 to Lines.Count - 1 do
      begin
        Parts.Clear;
        Parts.Delimiter := '|';
        Parts.StrictDelimiter := True;
        Parts.DelimitedText := Lines[I];

        if Parts.Count <> 2 then
        begin
          AllValid := False;
          Break;
        end;

        PackageName := Parts[1];
        State := Parts[0] = '1';

        if AppListBox.Items.IndexOf(PackageName) = -1 then
        begin
          AllValid := False; // пакет не найден
          Break;
        end;
      end;

      if not AllValid then
      begin
        MessageDlg(SFileNotValid, mtWarning, [mbOK], 0);
        SetItemIndexSafely(0);
        Exit;
      end;

      // Все строки валидные — применяем галки
      for I := 0 to Lines.Count - 1 do
      begin
        Parts.Clear;
        Parts.DelimitedText := Lines[I];
        PackageName := Parts[1];
        State := Parts[0] = '1';

        AppListBox.Checked[AppListBox.Items.IndexOf(PackageName)] := State;
      end;

      SetItemIndexSafely(0);

    finally
      Lines.Free;
      Parts.Free;
    end;
  end;
end;

//Режим: Отключение или Удаление приложений
procedure TCheckForm.ModeBoxChange(Sender: TObject);
begin
  if AppListBox.Count <> 0 then
  begin
    ClearBtn.Click;

    if ModeBox.Checked then
      //Снимаем все чекбоксы
      AppListBox.CheckAll(cbUnchecked)
    else
    begin
      AppListBox.Clear;
      //Запуск потока загрузки списка приложений
      StartThread;
    end;
  end;
end;

//URL IconExtractor.apk
procedure TCheckForm.PkgBtnClick(Sender: TObject);
begin
  OpenURL('https://github.com/AKotov-dev/adbmanager/tree/main/IconExtractor');
end;

//Не открываем меню нсли список пуст
procedure TCheckForm.PopupMenu1Popup(Sender: TObject);
begin
  if (AppListBox.Count = 0) or (not ApplyBtn.Enabled) then Abort;
end;

//Сохранить список в *.txt
procedure TCheckForm.SaveToFileClick(Sender: TObject);
var
  S: TStringList;
  i: integer;
begin
  try
    S := TStringList.Create;
    for i := 0 to AppListBox.Count - 1 do
    begin
      if AppListBox.Checked[i] then S.Add('1|' + AppListBox.Items[i])
      else
        S.Add('0|' + AppListBox.Items[i]);
    end;

    if SaveDialog1.Execute then
    begin
      if LowerCase(ExtractFileExt(SaveDialog1.FileName)) <> '.txt' then
        SaveDialog1.FileName := ChangeFileExt(SaveDialog1.FileName, '.txt');

      S.SaveToFile(SaveDialog1.FileName);

      //Указатель на верхнюю запись списка
      SetItemIndexSafely(0);
    end;
  finally
    S.Free;
  end;
end;

//Поиск в списке по части *имени_приложения*
procedure TCheckForm.Edit1Change(Sender: TObject);
var
  I, FirstFound: integer;
  SearchText: string;
begin
  if AppListBox.Count = 0 then Exit;

  SearchText := Trim(UpperCase(Edit1.Text));

  AppListBox.Items.BeginUpdate;
  try
    AppListBox.ClearSelection;
    FirstFound := -1;

    // Если поле пустое — выделить первый элемент и выйти
    if SearchText = '' then
    begin
      if AppListBox.Count > 0 then
      begin
        AppListBox.ItemIndex := 0;
        AppListBox.TopIndex := 0;
        AppListBox.Selected[0] := True;
      end;
      Exit;
    end;

    // Поиск совпадений
    for I := 0 to AppListBox.Items.Count - 1 do
      if Pos(SearchText, UpperCase(AppListBox.Items[I])) > 0 then
      begin
        AppListBox.Selected[I] := True;
        if FirstFound = -1 then
          FirstFound := I; // запоминаем первый найденный
      end;

    // Прокрутить к первому найденному
    if FirstFound <> -1 then
    begin
      AppListBox.ItemIndex := FirstFound;
      AppListBox.TopIndex := FirstFound;
    end;
  finally
    AppListBox.Items.EndUpdate;
  end;
end;

//Очищаем виртуальный список чекеров, сохраняем настройки формы
procedure TCheckForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  StopThread; // гарантированно завершить поток

  if not Assigned(FReadThread) then
    SaveSettings;
end;

procedure TCheckForm.FormCreate(Sender: TObject);
begin
  LoadSettings;
end;

//Применение параметров: Включение/Отключение/Удаление приложений
procedure TCheckForm.ApplyBtnClick(Sender: TObject);
var
  a: boolean;
  i: integer;
  adbcmd: string;
begin
  a := False;
  adbcmd := '';
  try
    //Удаление?
    if ModeBox.Checked then
    begin
      //Выбран ли хоть один чекер?
      for i := 0 to AppListBox.Count - 1 do
        if AppListBox.Checked[i] = True then
        begin
          a := True;
          Break;
        end;

      if not a then CheckForm.Close
      else if MessageDlg(SDeleteAPK, mtWarning, [mbYes, mbNo], 0) <> mrYes then
        Exit;

      //Команда для удаления (замарозки) приложений
      for i := 0 to AppListBox.Count - 1 do
        if AppListBox.Checked[i] = True then
          adbcmd := adbcmd + 'adb shell pm uninstall --user 0 ' +
            AppListBox.Items[i] + ';';
    end
    else //Отключение?
    begin
      //Команда для отключения приложений (VBox - снимок чекеров списка, взятый из последнего потока)
      for i := 0 to VList.Count - 1 do
        if AppListBox.Checked[i] <> StrToBool(VList[i]) then
        begin
          if AppListBox.Checked[i] = True then
            adbcmd := adbcmd + 'adb shell pm enable --user 0 ' +
              AppListBox.Items[i] + ';'
          else
            adbcmd := adbcmd + 'adb shell pm disable-user --user 0 ' +
              AppListBox.Items[i] + ';';
        end;
    end;

    //Запуск команды и потока отображения лога исполнения
    if adbcmd <> '' then
      StartADBCommand.Create(adbcmd);

  finally
    VList.Free;
    CheckForm.Close;
  end;
end;

//Отрисовка иконок приложений для виджетов GTK2 и Qt6  ---
procedure TCheckForm.AppListBoxDrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
begin
  {$IFDEF LCLQt6}
      DrawQt6Item(AppListBox, Index, ARect, State);
  {$ELSE}
  DrawGTK2Item(AppListBox, Index, ARect, State);
  {$ENDIF}
end;

// --- Qt6 вариант с чекбоксами ---
procedure TCheckForm.DrawQt6Item(CLB: TCheckListBox; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  bmp: TBitmap;
  png: TPortableNetworkGraphic;
  fname: string;
  textY, iconTop, iconHeight, checkBoxSize, checkBoxTop: integer;
  checkBoxRect, fillRect: TRect;
  boxColor: TColor;
begin
  // --- фон строки ---
  if odSelected in State then
    CLB.Canvas.Brush.Color := clHighlight
  else
    CLB.Canvas.Brush.Color := CLB.Color;
  CLB.Canvas.FillRect(ARect);

  // --- чекбокс ---
  checkBoxSize := 18;
  checkBoxTop := ARect.Top + ((ARect.Bottom - ARect.Top) - checkBoxSize) div 2;
  checkBoxRect := Rect(ARect.Left + 4, checkBoxTop, ARect.Left +
    4 + checkBoxSize, checkBoxTop + checkBoxSize);

  CLB.Canvas.Pen.Width := 1;
  CLB.Canvas.RoundRect(checkBoxRect.Left, checkBoxRect.Top,
    checkBoxRect.Right, checkBoxRect.Bottom, 4, 4);

  // Цвет включенного чекера
  if CLB.Checked[Index] then
  begin
    boxColor := RGB(30, 144, 255);
    CLB.Canvas.Brush.Color := boxColor;
    fillRect := Rect(checkBoxRect.Left + 4, checkBoxRect.Top + 4,
      checkBoxRect.Right - 4, checkBoxRect.Bottom - 4);
    CLB.Canvas.FillRect(fillRect);
  end;

  // --- иконка ---
  fname := GetEnvironmentVariable('HOME') + '/.adbmanager/icons/' +
    CLB.Items[Index] + '.png';
  if FileExists(fname) then
  begin
    png := TPortableNetworkGraphic.Create;
    bmp := TBitmap.Create;
    try
      png.LoadFromFile(fname);
      bmp.Assign(png);
      iconHeight := bmp.Height;
      iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;
      CLB.Canvas.Draw(checkBoxRect.Right + 7, iconTop, bmp);
    finally
      png.Free;
      bmp.Free;
    end;
  end
  else
  begin
    iconHeight := DefaultIcon.Height;
    iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;
    DefaultIcon.Draw(CLB.Canvas, checkBoxRect.Right + 6, iconTop, 0, True);
  end;

  // --- текст ---
  CLB.Canvas.Brush.Style := bsClear;
  textY := ARect.Top + ((ARect.Bottom - ARect.Top) -
    CLB.Canvas.TextHeight(CLB.Items[Index])) div 2;
  CLB.Canvas.TextOut(checkBoxRect.Right + 8 + iconHeight + 5, textY, CLB.Items[Index]);
  CLB.Canvas.Brush.Style := bsSolid;
end;


// --- GTK2 вариант без чекбоксов ---
procedure TCheckForm.DrawGTK2Item(CLB: TCheckListBox; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  bmp: TBitmap;
  png: TPortableNetworkGraphic;
  fname: string;
  textY, iconTop, textHeight, iconHeight: integer;
begin
  CLB.Canvas.FillRect(ARect);

  // --- иконка ---
  fname := GetEnvironmentVariable('HOME') + '/.adbmanager/icons/' +
    CLB.Items[Index] + '.png';
  if FileExists(fname) then
  begin
    png := TPortableNetworkGraphic.Create;
    bmp := TBitmap.Create;
    try
      png.LoadFromFile(fname);
      bmp.Assign(png);
      iconHeight := bmp.Height;
      iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;
      CLB.Canvas.Draw(ARect.Left + 2, iconTop, bmp);
    finally
      png.Free;
      bmp.Free;
    end;
  end
  else
  begin
    iconHeight := DefaultIcon.Height;
    iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;
    DefaultIcon.Draw(CLB.Canvas, ARect.Left + 2, iconTop, 0, True);
  end;

  // --- текст ---
  textHeight := CLB.Canvas.TextHeight(CLB.Items[Index]);
  textY := ARect.Top + ((ARect.Bottom - ARect.Top) - textHeight) div 2;
  CLB.Canvas.TextOut(ARect.Left + iconHeight + 6, textY, CLB.Items[Index]);
end;
//-----------------------------------------------------------


//Очистка поиска
procedure TCheckForm.ClearBtnClick(Sender: TObject);
begin
  Edit1.Clear;
  if AppListBox.Count <> 0 then AppListBox.ItemIndex := 0;
end;

//Название пакета в буфер обмена
procedure TCheckForm.CopyToClipboardClick(Sender: TObject);
begin
  ClipBoard.AsText := AppListBox.Items[AppListBox.ItemIndex];
end;

end.
