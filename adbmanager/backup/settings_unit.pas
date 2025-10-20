unit settings_unit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  ExtCtrls, IniPropStorage, ComCtrls, XMLPropStorage;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    CheckGroup1: TCheckGroup;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    ProgressBar1: TProgressBar;
    ApplyBtn: TSpeedButton;
    TrackBar1: TTrackBar;
    XMLPropStorage1: TXMLPropStorage;
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  SettingsForm: TSettingsForm;

resourcestring
  SSystemSound = 'System sounds such as clicks when buttons are pressed';
  SVibration = 'Vibration when pressing buttons or other actions';
  SSecNotifications =
    'Security notifications, such as notifications that the device is password protected';
  SAutomaticSync = 'Automatic synchronization of accounts (Google, Facebook, etc.)';
  SInterfaceAnimation1 =
    'Animation of transitions between screens and different states (transition_animation_scale)';
  SInterfaceAnimation2 =
    'Animation of button presses, scaling of elements (animator_duration_scale)';
  SInterfaceAnimation3 =
    'Animation of opening, closing and moving windows (window_animation_scale)';
  SAutoRotateScreen = 'Enable or disable auto-rotate screen';
  SAutoUpdate = 'Automatic system update';
  SPowerSavingMode = 'Power saving mode';


implementation

uses unit1, ReadSettingsTRDUnit, WriteSettingsTRDUnit;

  {$R *.lfm}

  { TSettingsForm }

//Показ формы
procedure TSettingsForm.FormShow(Sender: TObject);
var
  i: integer;
begin
  //For Plasma
  XMLPropStorage1.Restore;

  //Обнуляем все чеки для чистой загрузки из потока
  for i := 0 to CheckGroup1.Items.Count - 1 do
    CheckGroup1.Checked[i] := False;

  CheckGroup1.Items[0] := SSystemSound;
  CheckGroup1.Items[1] := SVibration;
  CheckGroup1.Items[2] := SSecNotifications;
  CheckGroup1.Items[3] := SAutomaticSync;
  CheckGroup1.Items[4] := SInterfaceAnimation1;
  CheckGroup1.Items[5] := SInterfaceAnimation2;
  CheckGroup1.Items[6] := SInterfaceAnimation3;
  CheckGroup1.Items[7] := SAutoRotateScreen;
  CheckGroup1.Items[8] := SAutoUpdate;
  CheckGroup1.Items[9] := SPowerSavingMode;

  //Уровень громкости
  TrackBar1.Position := 0;

  //Размер шрифта
  ComboBox1.Text := '...';

  //Запуск потока чтения настроек
  ReadSettingsTRD.Create(False);
end;

procedure TSettingsForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  XMLPropStorage1.Save;
end;

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  XMLPropStorage1.FileName := MainForm.XMLPropStorage1.FileName;
end;

//Применить
procedure TSettingsForm.ApplyBtnClick(Sender: TObject);
begin
  //Запуск потока записи настроек
  WriteSettingsTRD.Create(False);
end;

end.
