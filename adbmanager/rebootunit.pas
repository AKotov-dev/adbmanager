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
    procedure CancelBtnClick(Sender: TObject);
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

uses unit1, SDCardManager;

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

//Выбор перезагрузки (короткая команда, индикатор не нужен)
procedure TRebootForm.OKBtnClick(Sender: TObject);
begin
  //Закрываем SD-Manager, если открыт
  MainForm.ActiveFormClose;

  //Обработка команд перезагрузки
  case RadioGroup1.ItemIndex of
    0: MainForm.StartProcess('adb reboot');
    1: MainForm.StartProcess('adb reboot bootloader');
    2: MainForm.StartProcess('adb reboot recovery');
    3: MainForm.StartProcess('adb shell reboot -p');
  end;

  Close;
end;

procedure TRebootForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Application.ProcessMessages;
  Sleep(20);

  SaveSettings;
end;

procedure TRebootForm.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TRebootForm.FormShow(Sender: TObject);
begin
  //For Plasma
  LoadSettings;
end;

end.
