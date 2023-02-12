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

  Edit1.Clear;
  AppListBox.Clear;
  ClearBtn.Width := Edit1.Height;

  //Виртуальный список для сравнения чекбоксов (исходный)
  VList := TStringList.Create;

  //Запуск потока загрузки списка приложений
  FReadAppsTRD := ReadAppsTRD.Create(False);
  FReadAppsTRD.Priority := tpNormal;
end;

//Поиск в списке по части слова
procedure TCheckForm.Edit1Change(Sender: TObject);
var
  I: integer;
begin
  AppListBox.Items.BeginUpdate;
  try
    for I := 0 to AppListBox.Items.Count - 1 do
      AppListBox.Selected[I] := ContainsText(AppListBox.Items[I], Edit1.Text);
  finally
    AppListBox.Items.EndUpdate;
  end;
end;

procedure TCheckForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  VList.Free;
  IniPropStorage1.Save;
end;

procedure TCheckForm.FormCreate(Sender: TObject);
begin
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

//Применение параметров Включения/Отключения
procedure TCheckForm.ApplyBtnClick(Sender: TObject);
var
  i: integer;
begin
  adbcmd := '';

  for i := 0 to VList.Count - 1 do
    if AppListBox.Checked[i] <> StrToBool(VList[i]) then
    begin
      if AppListBox.Checked[i] = True then
        adbcmd := adbcmd + 'adb shell pm enable ' + AppListBox.Items[i] + ';'
      else
      if ModeBox.Checked then
        adbcmd := adbcmd + 'adb shell pm disable-user --user 0 ' +
          AppListBox.Items[i] + ';'
      else
        adbcmd := adbcmd + 'adb shell pm disable ' + AppListBox.Items[i] + ';';
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
