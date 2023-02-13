unit CheckUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CheckLst, StdCtrls,
  IniPropStorage, ComCtrls, Buttons, StrUtils;

type

  { TCheckForm }

  TCheckForm = class(TForm)
    AppListBox: TCheckListBox;
    ApplyBtn: TButton;
    ModeBox: TCheckBox;
    Edit1: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    ClearBtn: TSpeedButton;
    procedure ApplyBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ModeBoxClick(Sender: TObject);
  private

  public

  end;

var
  CheckForm: TCheckForm;
  VList: TStringList;

implementation

uses Unit1, ReadAppsTrdUnit;

{$R *.lfm}

{ TCheckForm }

procedure TCheckForm.FormShow(Sender: TObject);
var
  FReadAppsTRD: TThread;
begin
  //For Plasma
  IniPropStorage1.Restore;

  AppListBox.Clear;
  Edit1.Clear;
  ModeBox.Checked := False;
  ClearBtn.Width := Edit1.Height;

  //Виртуальный список для сравнения чекбоксов (исходный)
  VList := TStringList.Create;

  //Запуск потока загрузки списка приложений
  FReadAppsTRD := ReadAppsTRD.Create(False);
  FReadAppsTRD.Priority := tpNormal;
end;

//Режим: Отключение или Удаление приложений
procedure TCheckForm.ModeBoxClick(Sender: TObject);
var
  FReadAppsTRD: TThread;
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
      FReadAppsTRD := ReadAppsTRD.Create(False);
      FReadAppsTRD.Priority := tpNormal;
    end;
  end;
end;

//Поиск в списке по части *имени_приложения*
procedure TCheckForm.Edit1Change(Sender: TObject);
var
  I: integer;
begin
  //Обход при Form.ShowModal, списка ещё нет
  if AppListBox.Count = 0 then Exit;

  AppListBox.Items.BeginUpdate;
  try
    for I := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Selected[I] := ContainsText(AppListBox.Items[I], Edit1.Text);
  finally
    AppListBox.Items.EndUpdate;
  end;
end;

//Очищаем виртуальный список чекеров, сохраняем настройки формы
procedure TCheckForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  VList.Free;
  IniPropStorage1.Save;
end;

procedure TCheckForm.FormCreate(Sender: TObject);
begin
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

//Применение параметров: Включение/Отключение/Удаление приложений
procedure TCheckForm.ApplyBtnClick(Sender: TObject);
var
  a: boolean;
  i: integer;
begin
  a := False;
  adbcmd := '';

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

    //Команда для удаления приложений
    for i := 0 to AppListBox.Count - 1 do
      if AppListBox.Checked[i] = True then
        adbcmd := adbcmd + 'adb shell pm uninstall -k --user 0 ' +
          AppListBox.Items[i] + ';';
  end
  else //Отключение?
  begin
    //Команда для отключения приложений
    for i := 0 to VList.Count - 1 do
      if AppListBox.Checked[i] <> StrToBool(VList[i]) then
      begin
        if AppListBox.Checked[i] = True then
          adbcmd := adbcmd + 'adb shell pm enable ' + AppListBox.Items[i] + ';'
        else
          adbcmd := adbcmd + 'adb shell pm disable-user --user 0 ' +
            AppListBox.Items[i] + ';';
      end;
  end;

  //Запуск команды и потока отображения лога исполнения
  if adbcmd <> '' then
    MainForm.StartADBCmd;

  CheckForm.Close;
end;

//Очистка поиска
procedure TCheckForm.ClearBtnClick(Sender: TObject);
begin
  Edit1.Clear;
  if AppListBox.Count <> 0 then AppListBox.ItemIndex := 0;
end;

end.
