unit EmulatorUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IniPropStorage;

type

  { TEmulatorForm }

  TEmulatorForm = class(TForm)
    CancelBtn: TButton;
    Edit1: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    OKBtn: TButton;
    RadioGroup1: TRadioGroup;
    procedure Edit1Enter(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
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

uses unit1, SDCardManager;

{$R *.lfm}

{ TEmulatorForm }


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
  RadioGroup1.Items[0] := SSwitchToUSB;
  RadioGroup1.Items[1] := SSwitchToTCPIP;
  RadioGroup1.Items[2] := SScanActiveConnection;

  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
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
  IniPropStorage1.Restore;
end;

procedure TEmulatorForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TEmulatorForm.Edit1Enter(Sender: TObject);
begin
  RadioGroup1.ItemIndex := -1;
end;

procedure TEmulatorForm.OKBtnClick(Sender: TObject);
begin
  //Если утройство не используется повторно
  if Pos(Edit1.Text, MainForm.DevSheet.Caption) = 0 then
  begin
    //Закрываем SD-Manager, если открыт
    if SDForm.Visible then
      SDForm.Close;

    //Отключаем терминал, если использовался
    MainForm.StartProcess('[ $(pidof sakura) ] && killall sakura');
  end;

  //Обработка команд Подключение/Сканирование
  case RadioGroup1.ItemIndex of
    0: adbcmd := 'adb usb';
    1: adbcmd := 'adb tcpip 5555';
    //Выделяем адрес вида x.x.x.x/nn
    2: adbcmd := 'nmap -sn $(ip a | grep -w $(ip route get 1.1.1.1 | awk ' +
        '''' + '{print $3}' + '''' + ' | cut -d "." -f1,2) | awk ' +
        '''' + '{print $2}' + '''' + ') | grep Nmap';
    else
      //Если введён валидный IP и он пингуется - выполняется коннект, иначе - отмена после ping -c3
      if IsIP(Trim(Edit1.Text)) then
        adbcmd := 'ping -c2 ' + Trim(Edit1.Text) + ' &> /dev/null && adb connect ' +
          Trim(Edit1.Text) + ':5555'
      else
        EmulatorForm.ModalResult := 2;
  end;
end;

end.
