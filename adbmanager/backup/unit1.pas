unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ComCtrls, ExtCtrls, IniPropStorage, Process;

type

  { TMainForm }

  TMainForm = class(TForm)
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Memo1: TMemo;
    DevicesTimer: TTimer;
    StaticText1: TStaticText;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    procedure DevicesTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label4ChangeBounds(Sender: TObject);
    procedure Label5ChangeBounds(Sender: TObject);
    procedure Label6ChangeBounds(Sender: TObject);
    procedure ToolButton10Click(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton6Click(Sender: TObject);
    procedure ToolButton7Click(Sender: TObject);
    procedure StartProcess(command: string);
    procedure ToolButton9Click(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

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

procedure TMainForm.ToolButton9Click(Sender: TObject);
begin
  Close;
end;

//Scan ADB Devices, status and adbkey
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
      Memo1.Lines.Assign(S);

    //Status-is-Active?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('systemctl is-active adb');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      Label4.Caption := Trim(S[0]);

    //Status-is-enabled?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('systemctl is-enabled adb');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      Label5.Caption := Trim(S[0]);

    //RSA Key?
    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('ls ~/.android | grep adbkey');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      Label6.Caption := 'yes'
    else
      Label6.Caption := 'no';

  finally
    S.Free;
    ExProcess.Free;
    DevicesTimer.Enabled := True;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  if not DirectoryExists('/root/.config') then
    MkDir('/root/.config');
  IniPropStorage1.IniFileName := '/root/.config/adbmonitor.conf';
end;

procedure TMainForm.Label4ChangeBounds(Sender: TObject);
begin
  if Label4.Caption = 'active' then
    Label4.Font.Color := clGreen
  else
    Label4.Font.Color := clRed;
end;

procedure TMainForm.Label5ChangeBounds(Sender: TObject);
begin
  if Label5.Caption = 'enabled' then
    Label5.Font.Color := clGreen
  else
    Label5.Font.Color := clRed;
end;

procedure TMainForm.Label6ChangeBounds(Sender: TObject);
begin
  if Label6.Caption = 'yes' then
    Label6.Font.Color := clGreen
  else
    Label6.Font.Color := clRed;
end;

procedure TMainForm.ToolButton10Click(Sender: TObject);
begin
  StartProcess('rm -rf ~/.android/*');
end;

procedure TMainForm.ToolButton1Click(Sender: TObject);
begin
  StartProcess('systemctl enable adb');
end;

procedure TMainForm.ToolButton2Click(Sender: TObject);
begin
  StartProcess('systemctl disable adb');
end;

procedure TMainForm.ToolButton5Click(Sender: TObject);
begin
  StartProcess('killall adb; systemctl stop adb; systemctl start adb');
end;

procedure TMainForm.ToolButton6Click(Sender: TObject);
begin
  Label4.Caption := 'stopping';
  StartProcess('systemctl stop adb');
end;

procedure TMainForm.ToolButton7Click(Sender: TObject);
begin
  Close;
end;

end.
