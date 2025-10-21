unit RebootUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, IniFiles;

type

  { TRebootForm }

  TRebootForm = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    RadioGroup1: TRadioGroup;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadSettings;
    procedure SaveSettings;

  private

  public

  end;

resourcestring
  SNormalReboot = 'Normal reboot';
  SBootLoader = 'Reboot to Bootloader';
  SRecoveryReboot = 'Reboot to Recovery mode';
  SShutDown = 'Shutdown the device';

var
  RebootForm: TRebootForm;

implementation

uses unit1, SDCardManager, ADBCommandTRD;

  {$R *.lfm}

  { TRebootForm }

//Сохранение настроек формы
procedure TRebootForm.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(CONF);
  try
    Ini.WriteInteger('RebootForm', 'Width', RebootForm.Width);
    Ini.WriteInteger('RebootForm', 'Height', RebootForm.Height);
  finally
    Ini.Free;
  end;
end;

//Загрузка настроек формы
procedure TRebootForm.LoadSettings;
var
  Ini: TIniFile;
begin
  if not FileExists(CONF) then Exit;
  Ini := TIniFile.Create(CONF);
  try
    RebootForm.Width := Ini.ReadInteger('RebootForm', 'Width', RebootForm.Width);
    RebootForm.Height := Ini.ReadInteger('RebootForm', 'Height', RebootForm.Height);
  finally
    Ini.Free;
  end;
end;

procedure TRebootForm.FormCreate(Sender: TObject);
begin
  LoadSettings;
  RadioGroup1.Items[0] := SNormalReboot;
  RadioGroup1.Items[1] := SBootLoader;
  RadioGroup1.Items[2] := SRecoveryReboot;
  RadioGroup1.Items[3] := SShutDown;
end;

procedure TRebootForm.OKBtnClick(Sender: TObject);
var
  adbcmd: string;
begin
  adbcmd := '';

  //Закрываем SD-Manager, если открыт
  if SDForm.Visible then
    SDForm.Close;

  //Отключаем терминал, если использовался
  //MainForm.StartProcess('[ $(pidof sakura) ] && killall -p sakura');
  MainForm.StartProcess('killall -q sakura');

  //Обработка команд перезагрузки
  case RadioGroup1.ItemIndex of
    0: adbcmd := 'adb reboot';
    1: adbcmd := 'adb reboot bootloader';
    2: adbcmd := 'adb reboot recovery';
    3: adbcmd := 'adb shell reboot -p';
  end;

  StartADBCommand.Create(adbcmd);
end;

procedure TRebootForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveSettings;
end;

procedure TRebootForm.FormShow(Sender: TObject);
begin
  //For Plasma
  LoadSettings;
end;

end.
