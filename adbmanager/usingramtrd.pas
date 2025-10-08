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
    FDevice: string;
    function GetConnectedDevice: string;
    function DeviceReachable: boolean;
    procedure UpdateLabel;
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

implementation

uses
  Unit1; // MainForm

constructor TRAMThread.Create;
begin
  FreeOnTerminate := True;
  inherited Create(False);
end;

function TRAMThread.GetConnectedDevice: string;
var
  P: TProcess;
  SL: TStringList;
  Line, SLine, Token: string;
begin
  Result := '';
  SL := TStringList.Create;
  P := TProcess.Create(nil);
  try
    P.Executable := '/bin/bash';
    P.Parameters.Add('-c');
    P.Parameters.Add('adb devices | tail -n +2');
    P.Options := [poUsePipes, poWaitOnExit];
    P.Execute;
    SL.LoadFromStream(P.Output);

    for Line in SL do
    begin
      SLine := Trim(Line);
      if (SLine = '') then Continue;

      if (Pos('device', SLine) > 0) and (Pos('offline', SLine) = 0) and
        (Pos('unauthorized', SLine) = 0) then // and (Pos(SNoDevice, SLine) = 0)
      begin
        Token := Trim(Copy(SLine, 1, Pos('device', SLine) - 1));
        Token := StringReplace(Token, #9, '', [rfReplaceAll]);
        Result := Trim(Token);
        Break;
      end;
    end;
  finally
    SL.Free;
    P.Free;
  end;
end;

function TRAMThread.DeviceReachable: boolean;
var
  P: TProcess;
  IPOnly: string;
begin
  Result := False;
  if Pos(':', FDevice) > 0 then
  begin
    IPOnly := Copy(FDevice, 1, Pos(':', FDevice) - 1);
    P := TProcess.Create(nil);
    try
      P.Executable := '/bin/bash';
      P.Parameters.Add('-c');
      P.Parameters.Add(Format('ping -c 1 -W 1 %s >/dev/null 2>&1', [IPOnly]));
      P.Options := [poWaitOnExit];
      P.Execute;
      Result := (P.ExitStatus = 0);
    finally
      P.Free;
    end;
  end
  else
    Result := True; // USB устройство всегда доступно
end;

procedure TRAMThread.Execute;
var
  Proc: TProcess;
  OutList: TStringList;
  Line, SLine, S: string;
  TotalKB, AvailKB: int64;
  MemFree, Buffers, Cached: int64;
begin
  OutList := TStringList.Create;
  try
    while not Terminated do
    begin
      FDevice := GetConnectedDevice;

      if (FDevice <> '') and DeviceReachable then
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
            Proc.Parameters.Add('-s');
            Proc.Parameters.Add(FDevice);
            Proc.Parameters.Add('shell');
            Proc.Parameters.Add('cat');
            Proc.Parameters.Add('/proc/meminfo');
            Proc.Options := [poUsePipes, poWaitOnExit];
            Proc.Execute;
            OutList.LoadFromStream(Proc.Output);

            for Line in OutList do
            begin
              SLine := Trim(Line);

              if Pos('MemTotal', SLine) > 0 then
              begin
                S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                Val(S, TotalKB);
              end
              else if Pos('MemAvailable', SLine) > 0 then
              begin
                S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                Val(S, AvailKB);
              end
              else if Pos('MemFree', SLine) > 0 then
              begin
                S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                Val(S, MemFree);
              end
              else if Pos('Buffers', SLine) > 0 then
              begin
                S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                Val(S, Buffers);
              end
              else if Pos('Cached', SLine) > 0 then
              begin
                S := Trim(Copy(SLine, Pos(':', SLine) + 1, Length(SLine)));
                S := Trim(Copy(S, 1, Pos(' ', S) - 1));
                Val(S, Cached);
              end;
            end;
          finally
            Proc.Free;
          end;
        except
          // adb отвалился — оставляем нули
        end;

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
      end
      else
      begin
        // нет устройства или не пингуется
        FInfo.TotalGB := 0;
        FInfo.AvailGB := 0;
        FInfo.Percent := 0;
      end;

      if not Terminated then
        Synchronize(@UpdateLabel);

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
      Format('RAM: %.2f GB / %.2f GB (%.1f%%)',
      [FInfo.TotalGB, FInfo.AvailGB, FInfo.Percent]);
end;

end.
