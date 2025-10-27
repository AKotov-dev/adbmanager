unit EmulatorUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IniFiles;

type

  { TEmulatorForm }

  TEmulatorForm = class(TForm)
    CancelBtn: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    OKBtn: TButton;
    RadioGroup1: TRadioGroup;
    procedure CancelBtnClick(Sender: TObject);
    procedure Edit1Enter(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure SaveSettings;
    procedure LoadSettings;

  private

  public

  end;

resourcestring
  SSwitchToUSB = 'Switch to USB mode';
  SSwitchToTCPIP = 'Switch to TCP/IP mode';
  SScanActiveConnection = 'Scan active connection';

var
  EmulatorForm: TEmulatorForm;

implementation

uses unit1, SDCardManager, ADBCommandTRD;

  {$R *.lfm}

  { TEmulatorForm }


//Сохранение настроек формы
procedure TEmulatorForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(CONF);
  try
    Ini.WriteInteger('EmulatorForm', 'Width', EmulatorForm.Width);
    Ini.WriteInteger('EmulatorForm', 'Height', EmulatorForm.Height);
    Ini.WriteString('EmulatorForm', 'Edit1', Edit1.Text);
  finally
    Ini.Free;
  end;
end;

//Загрузка настроек формы
procedure TEmulatorForm.LoadSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(CONF) then Exit;
  Ini := TIniFile.Create(CONF);
  try
    EmulatorForm.Width := Ini.ReadInteger('EmulatorForm', 'Width', EmulatorForm.Width);
    EmulatorForm.Height := Ini.ReadInteger('EmulatorForm', 'Height',
      EmulatorForm.Height);

    Edit1.Text := Ini.ReadString('EmulatorForm', 'Edit1', Edit1.Text);
  finally
    Ini.Free;
  end;
end;

//Валидация IP-адреса
function IsIP(const S: string): boolean;
var
  i: integer;
  DotCount: integer;
  NumVal: integer;
begin
  Result := False;
  DotCount := 0;
  NumVal := 0;
  i := 1;
  while (i <= Length(S)) and (S[i] = ' ') do Inc(i);
  if (i <= Length(S)) and (S[i] = '.') then exit;
  while i <= Length(S) do
  begin
    if S[i] = '.' then
    begin
      Inc(DotCount);
      if (DotCount > 3) or (NumVal > 255) then exit;
      NumVal := 0;
      if (i >= Length(S)) or (not (S[i + 1] in ['0'..'9'])) then exit;
    end
    else
    if S[i] in ['0'..'9'] then
      NumVal := NumVal * 10 + Ord(S[i]) - Ord('0')
    else
    begin
      while (i <= Length(S)) and (S[i] = ' ') do Inc(i);
      if i <= Length(S) then exit;
      break;
    end;
    Inc(i);
  end;
  if (DotCount <> 3) or (NumVal > 255) then exit;
  Result := True;
end;

procedure TEmulatorForm.FormCreate(Sender: TObject);
begin
  LoadSettings;

  RadioGroup1.Items[0] := SSwitchToUSB;
  RadioGroup1.Items[1] := SSwitchToTCPIP;
  RadioGroup1.Items[2] := SScanActiveConnection;
end;

procedure TEmulatorForm.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  //Ловим Enter
  if Key = $0D then
    OkBtn.Click;
end;

procedure TEmulatorForm.FormShow(Sender: TObject);
begin
  //For Plasma
  LoadSettings;
end;

procedure TEmulatorForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Application.ProcessMessages;
  Sleep(20);

  SaveSettings;
end;

procedure TEmulatorForm.Edit1Enter(Sender: TObject);
begin
  RadioGroup1.ItemIndex := -1;
end;

procedure TEmulatorForm.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TEmulatorForm.OKBtnClick(Sender: TObject);
var
  adbcmd: string;
begin
  adbcmd := '';

  //Если устройство TCP/IP не используется повторно
  if Pos(Edit1.Text, MainForm.DevSheet.Caption) = 0 then
    MainForm.ActiveFormClose;

  //Обработка команд Подключение/Сканирование
  case RadioGroup1.ItemIndex of
    0: adbcmd := 'adb usb';
    1: adbcmd := 'adb tcpip 5555';
    //Выделяем адрес вида x.x.x.x/nn
    2: adbcmd := 'iface=$(ip route get 1.1.1.1 | awk ''{print $5}''); ' +
        'nmap -sn $(ip -o -4 addr show $iface | awk ''{print $4}'') | grep Nmap';

    else
      //Если введён валидный IP и он пингуется - выполняется коннект, иначе - отмена после ping -c3
      if IsIP(Trim(Edit1.Text)) then
        adbcmd := 'ping -c2 ' + Trim(Edit1.Text) + ' &> /dev/null && adb connect ' +
          Trim(Edit1.Text) + ':5555'
      else
        EmulatorForm.Close;
  end;

  if adbcmd <> '' then
    StartADBCommand.Create(adbcmd);

  Close;
end;

end.
