unit BackUpUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IniPropStorage;

type

  { TBackupForm }

  TBackupForm = class(TForm)
    CancelBtn: TButton;
    IniPropStorage1: TIniPropStorage;
    OKBtn: TButton;
    RadioGroup1: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private

  public

  end;

resourcestring
  SNoShared = 'Backup without SD-card';
  SShared = 'Full backup (long procedure)';

var
  BackupForm: TBackupForm;

implementation

uses unit1;

{$R *.lfm}

{ TBackupForm }

procedure TBackupForm.OKBtnClick(Sender: TObject);
var
  S: string;
begin
  //Имя бэкапа (сек + 1)
  S := Concat('backup-', FormatDateTime('dd-mm-yyyy_hh-nn-ss', Now), '.adb');
  MainForm.SaveDialog1.FileName := S;

  if MainForm.SaveDialog1.Execute then
  begin
    //Обработка команд бэкапа
    case RadioGroup1.ItemIndex of
      0: adbcmd := 'adb backup -apk -noshared -all -f "' +
          MainForm.SaveDialog1.FileName + '"';
      1: adbcmd := 'adb backup -apk -shared -all -f "' +
          MainForm.SaveDialog1.FileName + '"';
    end;
  end
  else
  begin
    ModalResult := mrCancel;
    Exit;
  end;
end;

procedure TBackupForm.FormCreate(Sender: TObject);
begin
  RadioGroup1.Items[0] := SNoShared;
  RadioGroup1.Items[1] := SShared;
  IniPropStorage1.IniFileName := MainForm.IniPropStorage1.IniFileName;
end;

end.
