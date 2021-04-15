unit RebootUnin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons;

type

  { TRebootForm }

  TRebootForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    RadioGroup1: TRadioGroup;
  private

  public

  end;

var
  RebootForm: TRebootForm;

implementation

{$R *.lfm}

end.

