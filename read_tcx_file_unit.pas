unit read_tcx_file_unit;

{$mode ObjFPC}{$H+}

interface

type
  TLap = record
    start_time: string;
    total_time_seconds: string;
    distance_meters: string;
    calories: string;
    average_heartrate_bpm: string;
    average_run_cadence: string;
  end;

  TTCXData = record
    laps: array of TLap;
    start_time: string;
    end_time: string;
  end;

function ReadTCXFile(filename: string): TTCXData;

implementation

uses
  laz2_xmlread,
  laz2_dom;

function SetZeroIfEmpty(s: string): string;
begin
  if s = '' then
    Result := '0'
  else
    Result := s;
end;

function ReadTCXFile(filename: string): TTCXData;
var
  doc: TXMLDocument;
  node1, node2, node3, node4, node5, node6: TDOMNode;
  lapno: integer = -1;
begin
  Result.laps := [];
  SetLength(Result.laps, 0);
  Result.start_time := '';
  Result.end_time := '';
  try
    ReadXMLfile(doc, filename);
    node1 := doc.DocumentElement.FindNode('Activities');
    if node1 <> nil then
    begin
      node2 := node1.FindNode('Activity');
      if node2 <> nil then
      begin
        node3 := node2.FirstChild;
        while node3 <> nil do
        begin
          if node3.NodeName = 'Id' then
            Result.start_time := node3.TextContent;
          if node3.NodeName = 'Lap' then
          begin
            Inc(lapno);
            SetLength(Result.laps, lapno + 1);
            Result.laps[lapno].average_heartrate_bpm := '0';
            Result.laps[lapno].average_run_cadence := '0';
            Result.laps[lapno].calories := '0';
            Result.laps[lapno].start_time :=
              node3.Attributes.GetNamedItem('StartTime').NodeValue;
            node4 := node3.FindNode('TotalTimeSeconds');
            if node4 <> nil then
              Result.laps[lapno].total_time_seconds := node4.TextContent;
            node4 := node3.FindNode('DistanceMeters');
            if node4 <> nil then
              Result.laps[lapno].distance_meters := node4.TextContent;
            node4 := node3.FindNode('Calories');
            if node4 <> nil then
              Result.laps[lapno].calories := SetZeroIfEmpty(node4.TextContent);
            node4 := node3.FindNode('Cadence');
            if node4 <> nil then
              Result.laps[lapno].average_run_cadence :=
                SetZeroIfEmpty(node4.TextContent);
            node4 := node3.FindNode('AverageHeartRateBpm');
            if node4 <> nil then
            begin
              node5 := node4.FindNode('Value');
              if node5 <> nil then
                Result.laps[lapno].average_heartrate_bpm :=
                  SetZeroIfEmpty(node5.TextContent);
            end;
            node4 := node3.FindNode('Extensions');
            if node4 <> nil then
            begin
              node5 := node4.FindNode('ns3:LX');
              if node5 <> nil then
              begin
                node6 := node5.FindNode('ns3:AvgRunCadence');
                if node6 <> nil then
                  Result.laps[lapno].average_run_cadence :=
                    SetZeroIfEmpty(node6.TextContent);
              end;
            end;
            if (node3.NextSibling = nil) or
              ((node3.NextSibling <> nil) and (node3.NextSibling.NodeName <> 'Lap')) then
            begin
              node4 := node3.FindNode('Track');
              if node4 <> nil then
              begin
                node5 := node4.LastChild;  // last Trackpoint
                if node5 <> nil then
                begin
                  node6 := node5.FindNode('Time');
                  if node6 <> nil then
                    Result.end_time := node6.TextContent;
                end;
              end;
            end;

          end;
          node3 := node3.NextSibling;
        end;
      end;
    end;
  finally
    doc.Free;
  end;
end;

end.
