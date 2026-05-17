unit get_tcx_data_unit;

{$mode ObjFPC}{$H+}

interface

procedure ProcessFile(filename: string);

implementation

uses
  DateUtils,
  Classes,
  SysUtils,
  Math,
  read_tcx_file_unit;

var
  Data: TTCXData;

function IsDSTGermany(dt: TDateTime): boolean;
var
  year: word;
  month: word;
  day: word;
  start_dst: TDatetime;
  end_dst: TDateTime;
begin
  Result := False;
  DecodeDate(dt, year, month, day);
  start_dst := EncodeDate(year, 3, 31);
  start_dst := start_dst - (DayOfWeek(start_dst) - 1) + Frac(StrToTime('02:00'));
  if year <= 1995 then
    end_dst := EncodeDate(year, 9, 30)
  else
    end_dst := EncodeDate(year, 10, 31);
  end_dst := end_dst - (DayOfWeek(end_dst) - 1) + Frac(StrToTime('03:00'));
  Result := (dt >= start_dst) and (dt < end_dst);
end;

function GetActivityStartDateTime(out startdt: TDateTime): string;
begin
  if Data.start_time <> '' then
  begin
    startdt := ISO8601ToDate(Data.start_time, True);
    startdt := IncHour(startdt, 1);
    if IsDSTGermany(startdt) then
      startdt := IncHour(startdt, 1);
    Exit(FormatDateTime('yyyy-mm-dd hh:nn', startdt));
  end;
  Result := 'Unknown';
end;

function GetActivityEndDateTime(out enddt: TDateTime): string;
begin
  if Data.end_time <> '' then
  begin
    enddt := ISO8601ToDate(Data.end_time, True);
    enddt := IncHour(enddt, 1);
    if IsDSTGermany(enddt) then
      enddt := IncHour(enddt, 1);
    Exit(FormatDateTime('yyyy-mm-dd hh:nn', enddt));
  end;
  Result := '- cannot be determined -';
end;

function GetActivityDistance(out dist: double): string;
var
  i: integer;
begin
  dist := 0;
  for i := 0 to High(Data.laps) do
    dist += StrToFloat(Data.laps[i].distance_meters);
  dist := Round(dist / 10.0) / 100.0;
  Result := FormatFloat('#0.00 km', dist);
end;

function GetActivityTimeHMS(out isecs: integer): string;
var
  i: integer;
  time: TDateTime;
  secs: double;
begin
  secs := 0;
  for i := 0 to High(Data.laps) do
    secs += StrToFloat(Data.laps[i].total_time_seconds);
  time := 0;
  isecs := Round(secs);
  time := IncSecond(time, isecs);
  Result := FormatDateTime('hh:nn:ss', time);
end;

function GetActivityCalories(out cals: double): string;
var
  i: integer;
begin
  Result := '- cannot be determined -';
  cals := 0;
  for i := 0 to High(Data.laps) do
    cals += StrToFloat(Data.laps[i].calories);
  cals := Round(cals);
  if cals > 0 then
    Result := Format('%.0f kcal', [cals]);
end;

function GetAverageHeartRate(out avghr: double): string;
var
  i: integer;
  secsum, secs: double;
begin
  Result := '- cannot be determined -';
  secsum := 0;
  avghr := 0;
  for i := 0 to High(Data.laps) do
  begin
    secs := StrToFloat(Data.laps[i].total_time_seconds);
    avghr += StrToFloat(Data.laps[i].average_heartrate_bpm) * secs;
    secsum += secs;
  end;
  avghr := Round(avghr / secsum);
  if avghr > 0 then
    Result := Format('%.0f bpm', [avghr]);
end;

function GetAverageCadence(out avgcad: double): string;
var
  i: integer;
  secsum, secs: double;
begin
  Result := '- cannot be determined -';
  secsum := 0;
  avgcad := 0;
  for i := 0 to High(Data.laps) do
  begin
    secs := StrToFloat(Data.laps[i].total_time_seconds);
    avgcad += StrToFloat(Data.laps[i].average_run_cadence) * secs;
    secsum += secs;
  end;
  avgcad := Ceil(2 * avgcad / secsum);
  if avgcad > 0 then
    Result := Format('%.0f spm', [avgcad]);
end;

function GetBestVelocity(out lapno: integer): double;
var
  dist, secs, v: double;
  i: integer;
begin
  Result := 0;
  lapno := 0;
  for i := 1 to High(Data.laps) - 1 do
  begin
    dist := StrToFloat(Data.laps[i].distance_meters);
    secs := StrToFloat(Data.laps[i].total_time_seconds);
    v := dist / secs * 3.6;
    if v > Result then
    begin
      Result := v;
      lapno := i + 1;
    end;
  end;
end;

procedure ProcessFile(filename: string);
var
  startdt, enddt: TDateTime;
  dist: double;
  secs: integer;
  cals: double;
  avghr: double;
  avgcad: double;
  bestv: double;
  stepl: double;
  lapnobest: integer;
begin
  try
    Data := ReadTCXFile(filename);
  except
    Writeln('File cannot be loaded: ', filename);
    Exit;
  end;
  writeln('Activity Start : ', GetActivityStartDateTime(startdt));
  writeln('Activity End   : ', GetActivityEndDateTime(enddt));
  writeln('Distance       : ', GetActivityDistance(dist));
  writeln('Moving Time    : ', GetActivityTimeHMS(secs));
  writeln('Total Time     : ', FormatDateTime('hh:nn:ss', enddt - startdt));
  writeln('Rest Time      : ', FormatDateTime('hh:nn:ss', enddt -
    startdt - secs / 86400));
  writeln('Number of laps : ', Length(Data.laps));
  writeln('Avg. Pace, Vel.: ', FormatDateTime('nn:ss', secs / (dist * 86400)),
    ' min/km, ',
    FormatFloat('#0.00 km/h', dist / secs * 3600));
  bestv := GetBestVelocity(lapnobest);
  if bestv = 0 then
    writeln('Best Pace, Vel.: - cannot be determined -')
  else
    writeln('Best Pace, Vel.: ', FormatDateTime('nn:ss', 3600. / (bestv * 86400)),
      ' min/km, ', FormatFloat('#0.00 km/h', bestv), ', in Lap ', lapnobest);
  writeln('Total Calories : ', GetActivityCalories(cals));
  writeln('Avg. Heartrate : ', GetAverageHeartRate(avghr));
  writeln('Avg. Cadence   : ', GetAverageCadence(avgcad));
  if avgcad = 0 then
    writeln('Avg. Step Len. : - cannot be determined -')
  else
  begin
    stepl := Round(dist * 1e6 / (avgcad * secs / 60.0)) / 10.0;
    writeln('Avg. Step Len. : ', Format('%.4g cm', [stepl]));
  end;
end;

end.
