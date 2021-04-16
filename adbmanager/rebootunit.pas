unit rebootunit;

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
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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

uses unit1;

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
  //Обработка команд перезагрузки
  case RadioGroup1.ItemIndex of
    0: adbcmd := 'adb reboot';
    1: adbcmd := 'adb reboot bootloader';
    2: adbcmd := 'adb reboot recovery';
    3: adbcmd := 'adb shell reboot -p';
  end;
end;

end.
