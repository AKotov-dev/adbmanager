unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process, LCLTranslator, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ActiveLabel: TLabel;
    EnabledLabel: TLabel;
    KeyLabel: TLabel;
    LogMemo: TMemo;
    DevicesTimer: TTimer;
    StaticText1: TStaticText;
    ToolBar1: TToolBar;
    EnableBtn: TToolButton;
    DeleteKeyBtn: TToolButton;
    ToolButton12: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    RestartBtn: TToolButton;
    StopBtn: TToolButton;
    ToolButton8: TToolButton;
    ExitBtn: TToolButton;
    procedure DevicesTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActiveLabelChangeBounds(Sender: TObject);
    procedure EnabledLabelChangeBounds(Sender: TObject);
    procedure KeyLabelChangeBounds(Sender: TObject);
    procedure DeleteKeyBtnClick(Sender: TObject);
    procedure EnableBtnClick(Sender: TObject);
    procedure DisableBtnClick(Sender: TObject);
    procedure RestartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure ExitBtnClick(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private

  public

  end;

resourcestring
    SDisable = 'Disable';
    SEnable = 'Enable';

var
  MainForm: TMainForm;

implementation

uses StartTRD;

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
    // ExProcess.Options := ExProcess.Options + [WaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

procedure TMainForm.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.ToggleBox1Change(Sender: TObject);
var
  FStartShowStatusThread: TThread;
begin
  //Запуск потока отображения статуса
  FStartShowStatusThread := ShowStatus.Create(False);
  FStartShowStatusThread.Priority := tpNormal;
end;

procedure TMainForm.DevicesTimerTimer(Sender: TObject);
var
  S: TStringList;
  ExProcess: TProcess;
begin
  DevicesTimer.Enabled := False;
  S := TStringList.Create;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('adb devices');
    ExProcess.Options := ExProcess.Options + [poUsePipes];
    ExProcess.Execute;

    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      LogMemo.Lines.Assign(S);

    //Status-is-active?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('systemctl is-active adb');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      ActiveLabel.Caption := Trim(S[0]);

    //Status-is-enabled?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('systemctl is-enabled adb');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      EnabledLabel.Caption := Trim(S[0]);

    //EnableButton change
    if EnabledLabel.Caption = 'disabled' then
    begin
      EnableBtn.Caption := 'Enable';
      EnableBtn.ImageIndex := 2;
    end
    else
    begin
      EnableBtn.Caption := 'Diasble';
      EnableBtn.ImageIndex := 3;
    end;

    //Key exists?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('ls ~/.android | grep adbkey');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      KeyLabel.Caption := 'yes'
    else
      KeyLabel.Caption := 'no';

  finally
    S.Free;
    DevicesTimer.Enabled := True;
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
  if not DirectoryExists('/root/.config') then
    MkDir('/root/.config');
  IniPropStorage1.IniFileName := '/root/.config/adbmanager.conf';
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

procedure TMainForm.DeleteKeyBtnClick(Sender: TObject);
begin
  StartProcess('rm -rf ~/.android/*');
end;

procedure TMainForm.EnableBtnClick(Sender: TObject);
begin
  if EnabledLabel.Caption = 'enabled' then
    StartProcess('systemctl disable adb')
  else
    StartProcess('systemctl enable adb');
end;

procedure TMainForm.DisableBtnClick(Sender: TObject);
begin
  StartProcess('systemctl disable adb');
end;

procedure TMainForm.RestartBtnClick(Sender: TObject);
begin
  StartProcess('killall adb; systemctl restart adb');
end;

procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  ActiveLabel.Caption := 'stopping';
  StartProcess('systemctl stop adb');
end;

end.
