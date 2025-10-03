unit CheckUnit;

{$mode ObjFPC}{$H+}

interface


uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CheckLst, StdCtrls,
  IniPropStorage, ComCtrls, Buttons, Types, LCLIntf, ReadAppsTrdUnit;

type

  { TCheckForm }

  TCheckForm = class(TForm)
    AppListBox: TCheckListBox;
    ApplyBtn: TButton;
    DefaultIcon: TImageList;
    ModeBox: TCheckBox;
    Edit1: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    ClearBtn: TSpeedButton;
    PkgBtn: TSpeedButton;
    procedure AppListBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ApplyBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure ModeBoxClick(Sender: TObject);
    procedure PkgBtnClick(Sender: TObject);
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

uses Unit1;

  {$R *.lfm}

  { TCheckForm }

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
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
  IniPropStorage1.Restore;

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

//Режим: Отключение или Удаление приложений
procedure TCheckForm.ModeBoxClick(Sender: TObject);
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

//Поиск в списке по части *имени_приложения*
procedure TCheckForm.Edit1Change(Sender: TObject);
var
  I: integer;
begin
  // Обход при Form.ShowModal, списка ещё нет
  if AppListBox.Count = 0 then Exit;

  AppListBox.Items.BeginUpdate;
  try
    for I := 0 to AppListBox.Items.Count - 1 do
      // Поиск подстроки
      AppListBox.Selected[I] :=
        Pos(UpperCase(Edit1.Text), UpperCase(AppListBox.Items[I])) > 0;
  finally
    AppListBox.Items.EndUpdate;
  end;
end;


//Очищаем виртуальный список чекеров, сохраняем настройки формы
procedure TCheckForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  StopThread; // гарантированно завершить поток

  // MainForm.StartProcess('adb shell am force-stop com.example.iconextractor');

  IniPropStorage1.Save;
end;

//Применение параметров: Включение/Отключение/Удаление приложений
procedure TCheckForm.ApplyBtnClick(Sender: TObject);
var
  a: boolean;
  i: integer;
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
            adbcmd := adbcmd + 'adb shell pm enable --user 0 ' + AppListBox.Items[i] + ';'
          else
            adbcmd := adbcmd + 'adb shell pm disable-user --user 0 ' +
              AppListBox.Items[i] + ';';
        end;
    end;

    //Запуск команды и потока отображения лога исполнения
    if adbcmd <> '' then
      MainForm.StartADBCmd;

  finally
    VList.Free;
    CheckForm.Close;
  end;
end;

//Отрисовка иконок приложений
procedure TCheckForm.AppListBoxDrawItem(Control: TWinControl;
  Index: integer; ARect: TRect; State: TOwnerDrawState);
var
  bmp: TBitmap;
  png: TPortableNetworkGraphic;
  fname: string;
  textY, iconTop: integer;
  textHeight, iconHeight: integer;
begin
  // фон строки
  (Control as TCheckListBox).Canvas.FillRect(ARect);

  fname := GetEnvironmentVariable('HOME') + '/.adbmanager/icons/' +
    AppListBox.Items[Index] + '.png';

  if FileExists(fname) then
  begin
    png := TPortableNetworkGraphic.Create;
    bmp := TBitmap.Create;
    try
      png.LoadFromFile(fname);
      bmp.Assign(png);
      iconHeight := bmp.Height;

      // вертикальное центрирование иконки
      iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;

      // рисуем PNG в оригинальном размере
      (Control as TCheckListBox).Canvas.Draw(ARect.Left + 2, iconTop, bmp);
    finally
      png.Free;
      bmp.Free;
    end;
  end
  else
  begin
    // fallback из ImageList
    iconHeight := DefaultIcon.Height;
    iconTop := ARect.Top + ((ARect.Bottom - ARect.Top) - iconHeight) div 2;
    DefaultIcon.Draw((Control as TCheckListBox).Canvas, ARect.Left +
      2, iconTop, 0, True);
  end;

  // вертикальное центрирование текста
  textHeight := AppListBox.Canvas.TextHeight(AppListBox.Items[Index]);
  textY := ARect.Top + ((ARect.Bottom - ARect.Top) - textHeight) div 2;

  // рисуем текст справа от иконки
  AppListBox.Canvas.TextOut(ARect.Left + iconHeight + 6, textY, AppListBox.Items[Index]);
end;


//Очистка поиска
procedure TCheckForm.ClearBtnClick(Sender: TObject);
begin
  Edit1.Clear;
  if AppListBox.Count <> 0 then AppListBox.ItemIndex := 0;
end;

end.
