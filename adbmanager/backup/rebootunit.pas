unit RebootUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, IniPropStorage;

type

  { TRebootForm }

  TRebootForm = class(TForm)
    IniPropStorage1: TIniPropStorage;
    OKBtn: TButton;
    CancelBtn: TButton;
    RadioGroup1: TRadioGroup;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

resourcestring
  SNormalReboot = 'Normal reboot';
  SBootLoader = 'Reboot to Bootloader';
  SRecoveryReboot = 'Reboot to Recovery mode';
  SShutDown = 'Shutdown the device (v4.4+)';

var
  RebootForm: TRebootForm;

implementation

uses unit1, SDCardManager;

{$R *.lfm}

{ TRebootForm }

procedure TRebootForm.FormCreate(Sender: TObject);
begin
  RadioGroup1.Items[0] := SNormalReboot;
  RadioGroup1.Items[1] := SBootLoader;
  RadioGroup1.Items[2] := SRecoveryReboot;
  RadioGroup1.Items[3] := SShutDown;
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

procedure TRebootForm.OKBtnClick(Sender: TObject);
begin
  //Закрываем SD-Manager, если открыт
  if SDForm.Visible then
    SDForm.Close;

  //Отключаем терминал, если использовался
  MainForm.StartProcess('[ $(pidof sakura) ] && killall sakura');

  //Обработка команд перезагрузки
  case RadioGroup1.ItemIndex of
    0: adbcmd := 'adb reboot';
    1: adbcmd := 'adb reboot bootloader';
    2: adbcmd := 'adb reboot recovery';
    3: adbcmd := 'adb shell reboot -p';
  end;
end;

procedure TRebootForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TRebootForm.FormShow(Sender: TObject);
begin
  //For Plasma
  IniPropStorage1.Restore;
end;

end.
