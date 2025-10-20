unit RebootUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, XMLPropStorage;

type

  { TRebootForm }

  TRebootForm = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    RadioGroup1: TRadioGroup;
    XMLPropStorage1: TXMLPropStorage;
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
  SShutDown = 'Shutdown the device';

var
  RebootForm: TRebootForm;

implementation

uses unit1, SDCardManager, ADBCommandTRD;

  {$R *.lfm}

  { TRebootForm }

procedure TRebootForm.FormCreate(Sender: TObject);
begin
  XMLPropStorage1.FileName := MainForm.XMLPropStorage1.FileName;
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
  CloseAction := caFree;
end;

procedure TRebootForm.FormShow(Sender: TObject);
begin
  //For Plasma
  XMLPropStorage1.Restore;
end;

end.
