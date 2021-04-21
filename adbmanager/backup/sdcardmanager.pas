unit SDCardManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ShellCtrls, ComCtrls, Buttons, IniPropStorage, Process, Types;

type

  { TSDForm }

  TSDForm = class(TForm)
    CompDir: TShellTreeView;
    CopyFromSmartphone: TSpeedButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    MkPCDirBtn: TSpeedButton;
    ProgressBar1: TProgressBar;
    SDBox: TListBox;
    SDMemo: TMemo;
    Panel2: TPanel;
    Panel1: TPanel;
    CopyFromPC: TSpeedButton;
    SelectAllBtn: TSpeedButton;
    MkDirBtn: TSpeedButton;
    DelBtn: TSpeedButton;
    RefreshBtn: TSpeedButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    UpBtn: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure CopyFromSmartphoneClick(Sender: TObject);
    procedure CopyFromPCClick(Sender: TObject);
    procedure DelBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MkDirBtnClick(Sender: TObject);
    procedure MkPCDirBtnClick(Sender: TObject);
    procedure RefreshBtnClick(Sender: TObject);
    procedure SDBoxDblClick(Sender: TObject);
    procedure SDBoxDrawItem(Control: TWinControl; Index: Integer; ARect: TRect;
      State: TOwnerDrawState);
    procedure StartProcess(command: string);
    procedure UpBtnClick(Sender: TObject);
    procedure StartCommand;
  private

  public

  end;

resourcestring
  SDelete = 'Delete selected objects?';
  SOverwriteObject = 'Overwrite existing objects?';
  SObjectExists = 'The folder already exists!';
  SCreateDir = 'Create directory';
  SInputName = 'Enter the name without spaces::';

var
  SDForm: TSDForm;
  sdcmd: string; //Команда ADB

implementation

uses SDCommandTRD, Unit1;

{$R *.lfm}

{ TSDForm }

//Исполнения команд/вывод лога
procedure TSDForm.StartCommand;
var
  FSDCommandThread: TThread;
begin
  //Запуск команды и потока отображения лога исполнения
  FSDCommandThread := StartSDCommand.Create(False);
  FSDCommandThread.Priority := tpNormal;
end;

//ls в директории /sdcard/...
procedure TSDForm.StartProcess(command: string);
var
  S: TStringList;
  ExProcess: TProcess;
begin
  S := TStringList.Create;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    ExProcess.Options := [poWaitOnExit, poUsePipes, poStderrToOutPut];
    ExProcess.Execute;

    SDBox.Items.LoadFromStream(ExProcess.Output);
  finally
    S.Free;
    ExProcess.Free;
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

      StartProcess('adb shell ls -F ' + GroupBox2.Caption + '| sort -k 1,1 | sort');

      if SDBox.Count > 0 then
        SDBox.ItemIndex := 0;

      break;
    end;
end;

//Домашний каталог текущий
procedure TSDForm.FormCreate(Sender: TObject);
begin
  CompDir.Root := ExcludeTrailingPathDelimiter(GetUserDir);
  CompDir.Items.Item[0].Selected := True;
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

procedure TSDForm.CopyFromPCClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  e := False;
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
          if Pos(ExtractFileName(CompDir.Items[i].GetTextPath),
            SDBox.Items.Text) <> 0 then
            e := True;

        c := 'adb push ' + ExcludeTrailingPathDelimiter(CompDir.Items[i].GetTextPath) +
          ' ' + GroupBox2.Caption;

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

procedure TSDForm.CopyFromSmartphoneClick(Sender: TObject);
var
  i: integer;
  c: string;
  e: boolean;
begin
  e := False; //Флаг совпадения файлов/папок (перезапись)
  sdcmd := '';  //Команда

  if SDBox.SelCount <> 0 then
  begin
    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if not e then
          if (FileExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            ExtractFileName(GroupBox2.Caption + Copy(SDBox.Items[i],
            3, Length(SDBox.Items[i]))))) or
            (DirectoryExists(ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected)) +
            ExtractFileName(GroupBox2.Caption + Copy(SDBox.Items[i],
            3, Length(SDBox.Items[i]))))) then
            e := True;

        c := 'adb pull ' + GroupBox2.Caption +
          Copy(SDBox.Items[i], 3, Length(SDBox.Items[i])) + ' ' +
          ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected));

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

procedure TSDForm.Button1Click(Sender: TObject);
begin
  SDBox.SelectAll;
end;

procedure TSDForm.DelBtnClick(Sender: TObject);
var
  i: integer;
  c: string; //сборка команд...
begin
  if MessageDlg(SDelete, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  sdcmd := '';

  if SDBox.SelCount <> 0 then
  begin

    for i := 0 to SDBox.Count - 1 do
    begin
      if SDBox.Selected[i] then
      begin
        if Copy(SDBox.Items[i], 1, 1) = 'd' then
          c := 'adb shell rm -rf ' + GroupBox2.Caption +
            Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]))
        else
          c := 'adb shell rm -f ' + GroupBox2.Caption +
            Copy(SDBox.Items[i], 3, Length(SDBox.Items[i]));

        sdcmd := c + '; ' + sdcmd;
      end;
    end;
    StartCommand;
  end;
end;

procedure TSDForm.FormShow(Sender: TObject);
begin
  //Перечитываем корень CompDir (могли быть изменения на диске извне)
  CompDir.Select(CompDir.TopItem, [ssCtrl]);
  CompDir.Refresh(CompDir.Selected.Parent);
  CompDir.Select(CompDir.TopItem, [ssCtrl]);
  CompDir.SetFocus;

  //Вся SDCard
  StartProcess('adb shell ls -F /sdcard/ | sort -k 1,1 | sort');

  //Возвращаем исходную директорию SD-Card
  GroupBox2.Caption := '/sdcard/';

  if SDBox.Count > 0 then
    SDBox.ItemIndex := 0;
end;

procedure TSDForm.MkDirBtnClick(Sender: TObject);
var
  S: string;
begin
  S := '';
  repeat
    if not InputQuery(SCreateDir, SInputName, S) then
      Exit
  until S <> '';

  sdcmd := 'adb shell mkdir ' + GroupBox2.Caption + S + '| sort -k 1,1 | sort';

  StartCommand;
end;

procedure TSDForm.MkPCDirBtnClick(Sender: TObject);
var
  S: string;
  i: integer;
begin
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

  MkDir(IncludeTrailingPathDelimiter(
    ExtractFilePath(CompDir.GetPathFromNode(CompDir.Selected))) + S);

  i := CompDir.Selected.AbsoluteIndex;
  CompDir.Refresh(CompDir.Selected.Parent);
  CompDir.Select(CompDir.Items[i], [ssCtrl]);

  if not CompDir.Selected.Expanded then
    CompDir.Refresh(CompDir.Selected);
  CompDir.SetFocus;
end;

procedure TSDForm.RefreshBtnClick(Sender: TObject);
begin
  //Перечитываем корень CompDir (могли быть изменения на диске извне)
  CompDir.Select(CompDir.TopItem, [ssCtrl]);
  CompDir.Refresh(CompDir.Selected.Parent);
  CompDir.Select(CompDir.TopItem, [ssCtrl]);
  CompDir.SetFocus;
end;

procedure TSDForm.SDBoxDblClick(Sender: TObject);
begin
  if Copy(SDBox.Items[SDBox.ItemIndex], 1, 1) = 'd' then
  begin
    GroupBox2.Caption := GroupBox2.Caption +
      Copy(SDBox.Items[SDBox.ItemIndex], 3,
      Length(SDBox.Items[SDBox.ItemIndex])) + '/';

    Screen.Cursor := crHourGlass;
    StartProcess('adb shell ls -F ' + GroupBox2.Caption + '| sort -k 1,1');

    if SDBox.Count > 0 then
      SDBox.ItemIndex := 0;

    Screen.Cursor := crDefault;
  end;
end;

procedure TSDForm.SDBoxDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
  var
    BitMap: TBitMap;
  begin
    BitMap := TBitMap.Create;
    try
      ImageList1.GetBitMap(0, BitMap);

      with TListBox(Control) do
      begin
        Canvas.FillRect(aRect);
        //Вывод текста со сдвигом
        Canvas.TextOut(aRect.Left + 15, aRect.Top + 5, Items[Index]);

        //Сверху иконки взависимости от первого символа
        if Copy(Items[Index], 1, 1) = 'd' then
        begin
          ImageList1.GetBitMap(0, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end
        else
        begin
          ImageList1.GetBitMap(1, BitMap);
          Canvas.Draw(aRect.Left + 2, aRect.Top + 2, BitMap);
        end;
      end;
    finally
      BitMap.Free;
    end;
  end;

end.
