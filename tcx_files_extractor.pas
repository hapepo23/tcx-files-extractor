program tcx_files_extractor;

{$mode objfpc}{$H+}

uses
  SysUtils,
  Classes,
  get_tcx_data_unit;

var
  dirinfo: TSearchRec;
  i: integer;
  filenames: TStringList;
  directory: string;

begin
  WriteLn('TCX Files Extractor started.');
  if ParamCount <= 0 then
  begin
    Writeln('No directory paths (Parameters 1..n) specified. Aborted.');
    Exit;
  end;
  filenames := TStringList.Create;
  for i := 1 to ParamCount do
  begin
    directory := Trim(ParamStr(i));
    WriteLn('Searching directory "', directory, '".');
    if not DirectoryExists(directory) then
    begin
      WriteLn('Directory "', directory, '" does not exist.');
      Break;
    end;
    ChDir(directory);
    if IOResult <> 0 then
    begin
      Writeln('Cannot change to directory "', directory, '".');
      Break;
    end;
    if FindFirst('*.tcx', faAnyFile and (not faDirectory), dirinfo) = 0 then
      repeat
        filenames.Add(directory + '/' + dirinfo.Name);
      until FindNext(dirinfo) <> 0;
    FindClose(dirinfo);
    if FindFirst('*.TCX', faAnyFile and (not faDirectory), dirinfo) = 0 then
      repeat
        filenames.Add(directory + '/' + dirinfo.Name);
      until FindNext(dirinfo) <> 0;
    FindClose(dirinfo);
  end;
  Writeln('Finished TCX file search. Found ', filenames.Count, ' TCX files.', LineEnding);
  filenames.Sort;
  for i := 1 to filenames.Count do
  begin
    WriteLn('File No. ', i: 5, ' : ', ExtractFileName(filenames.Strings[i - 1]));
    ProcessFile(filenames.Strings[i - 1]);
    WriteLn;
  end;
  filenames.Free;
  WriteLn('TCX Files Extractor finished.');
end.
