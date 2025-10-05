unit UsingRAMTRD;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process;

type
  TRAMInfo = record
    TotalGB: double;
    AvailGB: double;
    Percent: double;
  end;

  TRAMThread = class(TThread)
  private
    FInfo: TRAMInfo;
    procedure UpdateLabel;
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

implementation

uses Unit1; // MainForm

  { === Поток === }

constructor TRAMThread.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TRAMThread.Execute;
var
  Proc: TProcess;
  OutList: TStringList;
  Line, S: string;
  TotalKB, AvailKB: int64;
  MemFree, Buffers, Cached: int64;
begin
  OutList := TStringList.Create;
  try
    while not Terminated do
    begin
      TotalKB := 0;
      AvailKB := 0;
      MemFree := 0;
      Buffers := 0;
      Cached := 0;
      OutList.Clear;

      try
        Proc := TProcess.Create(nil);
        try
          Proc.Executable := 'adb';
          Proc.Parameters.Add('shell');
          Proc.Parameters.Add('cat');
          Proc.Parameters.Add('/proc/meminfo');
          Proc.Options := [poUsePipes, poWaitOnExit];
          Proc.Execute;
          OutList.LoadFromStream(Proc.Output);

          for Line in OutList do
          begin
            if Pos('MemTotal', Line) > 0 then
            begin
              S := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line)));
              S := Trim(Copy(S, 1, Pos(' ', S) - 1));
              Val(S, TotalKB);
            end
            else if Pos('MemAvailable', Line) > 0 then
            begin
              S := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line)));
              S := Trim(Copy(S, 1, Pos(' ', S) - 1));
              Val(S, AvailKB);
            end
            else if Pos('MemFree', Line) > 0 then
            begin
              S := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line)));
              S := Trim(Copy(S, 1, Pos(' ', S) - 1));
              Val(S, MemFree);
            end
            else if Pos('Buffers', Line) > 0 then
            begin
              S := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line)));
              S := Trim(Copy(S, 1, Pos(' ', S) - 1));
              Val(S, Buffers);
            end
            else if Pos('Cached', Line) > 0 then
            begin
              S := Trim(Copy(Line, Pos(':', Line) + 1, Length(Line)));
              S := Trim(Copy(S, 1, Pos(' ', S) - 1));
              Val(S, Cached);
            end;
          end;
        finally
          Proc.Free;
        end;
      except
        // если устройство не подключено — оставляем нули
      end;

      // если MemAvailable есть, используем его, иначе считаем через Free+Buffers+Cached
      if AvailKB = 0 then
        AvailKB := MemFree + Buffers + Cached;

      if TotalKB > 0 then
      begin
        FInfo.TotalGB := TotalKB / 1024 / 1024;
        FInfo.AvailGB := AvailKB / 1024 / 1024;
        FInfo.Percent := (AvailKB * 100) / TotalKB;
      end
      else
      begin
        FInfo.TotalGB := 0;
        FInfo.AvailGB := 0;
        FInfo.Percent := 0;
      end;

      try
        if not Terminated then
          Synchronize(@UpdateLabel);
      except
        Terminate;
      end;

      Sleep(500);
    end;
  finally
    OutList.Free;
  end;
end;

procedure TRAMThread.UpdateLabel;
begin
  if Assigned(MainForm) and Assigned(MainForm.LabelRAM) then
    MainForm.LabelRAM.Caption :=
      Format('RAM: %.2f GB / %.2f GB (%.1f%%)', [FInfo.TotalGB,
      FInfo.AvailGB, FInfo.Percent]);
end;

end.
