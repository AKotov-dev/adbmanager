unit rebootunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls;

type

  { TRebootForm }

  TRebootForm = class(TForm)
    OKBtn: TButton;
    Button2: TButton;
    RadioGroup1: TRadioGroup;
    procedure OKBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

resourcestring
  SNormalReboot = 'Normal reboot';
  SRecoveryReboot = 'Reboot into recovery';

var
  RebootForm: TRebootForm;

implementation

uses unit1;

{$R *.lfm}

{ TRebootForm }

procedure TRebootForm.FormCreate(Sender: TObject);
begin
  RadioGroup1.Items[0] := SNormalReboot;
  RadioGroup1.Items[1] := SRecoveryReboot;
end;

procedure TRebootForm.OKBtnClick(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 0 then
    adbcmd := 'adb reboot'
  else
    adbcmd := 'adb reboot recovery';
end;

end.
