unit Cfgprt;

{gns 13-Jan-1999}

{ 19981104,plr: Using sfSilentErrors to trap error messages while printing }
{ 19981204,plr: Made detailed config report parse DropCommands,OtherCommands and InputFields (for lookup sql)
 19990113,gns: Changes to enable compilation under Delphi 4
 19990113,gns: Removed out of date conditional compiles
 19990302,gns: Replaced StrPlus:TrimString functions with Delphi:Trim
 19990303,gns: Replaced Upper/LowerCase with ANSIUpper/LowerCase
 19990621,plr: Changed TQuery to TVersaQuery
 19990820,plr: Changed so OtherCommands would handle the new format
 19991115,rl: Replaced Inilib TTable with TQuery
 19991118,rl: Changed iniiddbedit to iniidedit
              changed inidescdbedit to inidescedit
 19991129,gns: Replaced BDE specific unit references with more generic ones
 20011008, gns: Eliminated defines SF40 and earlier and related obsolete code
 20011129,gns: Replaced Global variables with Session variables.
 20011212,rtr: Eliminated Orpheus controls.
 20020715,plr: Replaced old InputFieldsEditControl logic with new sub string list logic
 20030124,gns: Ensure string operations accomodate large strings. Ref TD# 4481
 20030501,rtr: Refactored Cfg Tool Form inheritance.
 20030507,gns: More robust handling of special characters. TD# 4921
 20030915,rtr: Refactoring
 20040920,ht : Remove hints and warnings.
 20041114,plr: Updated Ini Record Printing to handle SCRIPT udvs
 20050706,rtr: Refactoring to reduce unit dependencies.
 20060424,rtr: Refactoring to reduce unit dependencies.
}

{Sample Third line}

interface
uses
  IniLib
  ,IniStat
  ,SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, sfDlgs, StdCtrls, Buttons, ExtCtrls, DBCtrls, Mask, DB {, DBTables } { GNS 11-29-99 }
  ,sfDatasets
  ,Sf2kCmmn
  ,DelXtra
  ,StdTools
  ,TxtScrlr,TypInfo,StrPlus
  ,IniFind,IndtStrg
  ,SqlLib
  ,UDVeMain
  ,UDVProp { to get Font List }
  ,Printers
  ,IniPrt
  ,DBAccess
  ,UDVCtrl
  ,IniLib2
  ,ComCtrls
  ,FwSql
  ,FwSqlUtl
  ,FwConst
  ,SrchQry
  ,SubStrgs
  ,fwStrngs
  ,sfVars {07Mar2001, gns}
  ,Tabs, Dktools, Drawkit
  ,FwSqlCommon
  ,fwtypes
  ,CtrlBand
  ,ScriptUdv
  ,fwClasses
  ,SfGnuExport
  ,POBuilder
  ;

procedure PrintIniLibData(TheIniDlg: TIniLibMaintDlg;
            FromNode:TIniTreeNode; IncludeSiblings,
            IncludeComments,IncludeSQL,PrintCoreSQL,
            ExpandUDV,WriteSqlAtEnd,WriteUDVAtEnd,
            ListSQLIds,
            ListUDVIds,
            WriteStoredProcsAtEnd,
            ShowSpacesAsDots:Boolean;
            PrintUDVOpt:Integer;
            PrintToFile,
            PathForBitmaps:String);

procedure ExportIniLibLocalizationTable(TheIniDlg: TIniLibMaintDlg; FromNode:TIniTreeNode; FileName: string);

implementation

//uses  ;

procedure PrintIniLibData(TheIniDlg: TIniLibMaintDlg;
            FromNode:TIniTreeNode; IncludeSiblings,
            IncludeComments,IncludeSQL,PrintCoreSQL,
            ExpandUDV,WriteSqlAtEnd,WriteUDVAtEnd,
            ListSQLIds,
            ListUDVIds,
            WriteStoredProcsAtEnd,
            ShowSpacesAsDots:Boolean;
            PrintUDVOpt:Integer;
            PrintToFile,
            PathForBitmaps:String);

const TitleStyle : TFontStyles = [fsBold];
      TitleSize = 14;
      NormalStyle : TFontStyles = [];
      NormalSize = 10;
      CommentStyle : TFontStyles = [fsItalic];
      CommentSize = 10;
      HeaderStyle : TFontStyles = [];
      HeaderSize = 8;
      SQLStyle : TFontStyles = [fsBold];
      SQLSize = 10;
      CoreSQLStyle : TFontStyles = [];
      CoreSQLSize = 12;
      RightMargin = 0.5;
      TopMargin = 1.0;
      LeftMargin = 0.5;

var SkipIndentLevel : integer;
    PixelsPerInchVertical : LongInt;
    PixelsPerInchHorizontal : LongInt;
    AtX,AtY : LongInt;
    OnPage : integer;
    StoredProcList,
    UDVIdList,
    SqlIdList : TfwStringList;
    NodeCounter : LongInt;
    FullUDVIdList,
    FullSqlIdList : TfwStringList;
    Printfile : System.Text;
    IniStatus : TIniStatusWin;


  procedure GetStoredProcText(TheProcName:String; sl:TStrings);
  var TheSql : TfwStringList;
  begin
    TheSql := TfwStringList.Create;
    try
    sl.clear;
    TheSql.Add('select TEXT from ALL_SOURCE');
    TheSql.Add('  where NAME='+QuotedStr(TheProcName));
      try
      GetSQLQueryWithParamsTextBlob(FwDatabaseName, TheSql, [nil], sl, nil);
      except
      end;
    finally
    TheSql.Free;
    end;
  end;

  function GetStoredProcName(sl:TStrings):String;
  var loop,loc : integer;
      st : string;
  begin { we know we have a stored proc, look for name }
    Result := '';
    for loop := 0 to sl.count-1 do
      begin
        loc := pos('EXEC',sl[loop]);
        if loc > 0 then
          begin
            st := copy(sl[loop],loc+4, MaxInt); {gns 24Jan03 - Replaced 255 with MaxInt. Ref TD #4481}
            loc := pos('(',st);
            if loc <> 0
              then st := copy(st,1,loc-1);
            loc := pos(';',st);
            if loc <> 0
              then st := copy(st,1,loc-1);
            st := Trim(st);
            Result := st;
            exit;
          end;
      end;
  end;

  Function xCoord(x:real):LongInt;
  begin
    Result := round(x * PixelsPerInchHorizontal);
  end;

  Function yCoord(y:real):LongInt;
  begin
    Result := round(y * PixelsPerInchVertical);
  end;

  Function SpaceLeft:real; { returns printable page left, in inches }
  begin
    if PrintToFile = ''
      then Result := (Printer.PageHeight-AtY-xCoord(0.5)) / PixelsPerInchVertical
      else Result := 10;
  end;

  procedure MoveDown(Inch:Real);
  var loop : integer;
  begin
    if PrintToFile = '' then
      AtY := AtY + YCoord(Inch)
    else
      begin
        for loop := 1 to yCoord(Inch) do
          writeln(Printfile);
      end;
  end;

  procedure MoveDownOneLine;
  begin
    if PrintToFile = ''
      then AtY := AtY + abs(Printer.Canvas.Font.Height)
      else writeln(Printfile);
  end;

  procedure RequireSpace(num:real);
  begin { make sure a minimum amount of space is left on the page,
           othewise, move down so it will start printing on next page }
    if SpaceLeft < num
      then MoveDown(num);
  end;

  procedure PrintRightJustified(y:integer; const st:string);
  var x : LongInt;
  begin
    if PrintToFile <> '' then
      writeln(PrintFile,st)
    else
      begin
        x := (Printer.PageWidth-Printer.Canvas.TextWidth(st))-xCoord(RightMargin);
        Printer.Canvas.TextOut(x,AtY,st);
      end;
  end;

  procedure SetPrinter(TheSize:Integer; TheStyle:TFontStyles);
  begin
    if PrintToFile <> '' then exit;
    Printer.Canvas.Font.Size := TheSize;
    Printer.Canvas.Font.Style := TheStyle;
  end;

  procedure StartANewPage;
  var HoldSize : Integer;
      HoldStyle : TFontStyles;
      st : string;
  begin
    if PrintToFile <> '' then exit;

    HoldSize := Printer.Canvas.Font.Size;
    HoldStyle := Printer.Canvas.Font.Style;
    SetPrinter(HeaderSize,HeaderStyle);
    if OnPage <> 0 then
      Printer.NewPage;
    OnPage := OnPage+1;
    IniStatus.Label1.Caption := 'Printing page '+IntToStr(OnPage);
    AtY := YCoord(TopMargin) div 2;
    st := 'Ini Id: '+TheIniDlg.IniIdEdit.Text; { RL 11/15/1999 }  { RL 11/18/1999 }
    if TheIniDlg.IniDescEdit.Text <> ''   { RL 11/18/1999 }
      then st := st + ' - ' + copy(TheIniDlg.IniDescEdit.Text,1,40);
    st := st + '   Printed '+DatetimeToStr(now);
    st := st + '   Page '+IntToStr(OnPage);
    PrintRightJustified(AtY,st);
    AtY := YCoord(TopMargin);
    SetPrinter(HoldSize,HoldStyle);
  end;

  procedure ExpandTabs(var st:String);
  var loc : integer;
  begin { just does a straight replacement of 8 spaces for a tab, does
           not handle embedded tabs }
    while pos(#9,st) <> 0 do
      begin
        loc := pos(#9,st);
        delete(st,loc,1);
        insert('        ',st,loc);
      end;
  end;

  procedure PrintThisString(st:string; SpacesAsDots:Boolean);
  var LeadingSpaces : String;
      loop : integer;
      st2 : string;
  begin
    if (OnPage=0) or (SpaceLeft < 0) then
      StartANewPage;
    ExpandTabs(st);
    loop := 1;
    LeadingSpaces := '    '; { this keeps indented lines from showing left of the first line }
    while (loop < length(st)) and (loop < 30) and (st[loop]=' ') do
      begin
        LeadingSpaces := LeadingSpaces +' ';
        if SpacesAsDots
          then st[loop] := '·';
        loop := loop + 1;
      end;
    if PrintToFile <> '' then
      begin
        for loop := xCoord(LeftMargin) to (AtX-1) do
          write(PrintFile,' ');
        writeln(PrintFile,st);
        exit;
      end;
    repeat
      st2 := st;
      st := '';
      { this word wrap not terribly fast or efficient, but should be good enough }
      while (AtX+Printer.Canvas.TextWidth(st2) > Printer.PageWidth-xCoord(RightMargin)) do
        begin
          st := copy(st2,length(st2),1)+st;
          st2 := copy(st2,1,length(st2)-1);
        end;
      if st <> '' then { back up to complete word }
        begin
          while (st2 <> '') and (not (st2[length(st2)] in [' ',',','~','-'])) do
            begin
              st := copy(st2,length(st2),1)+st;
              st2 := copy(st2,1,length(st2)-1);
            end;
          st := LeadingSpaces+st;
          if length(st2) <= length(LeadingSpaces) then { no break, just print it }
            begin
              st2 := copy(st,1,50);
              delete(st,1,50);
            end;
        end;
      Printer.Canvas.TextOut(AtX,AtY,st2);
      MoveDownOneLine;
    until (st='');
  end;

  procedure PrintString(st:String);
  begin
    PrintThisString(st,false);
  end;

  procedure PrintStringWithDots(st:String);
  begin
    PrintThisString(st,ShowSpacesAsDots);
  end;


  procedure WriteSQL(st:String);
  var sl : TfwStringList;
      loop : integer;
  begin
    if (st='') or (AnsiUpperCase(st)='@NA') or (AnsiUpperCase(st)='(N/A)') then exit;
    FullSqlIdList.Add(st);
    if WriteSQLAtEnd then
      begin
        SqlIdList.Add(st);
        exit;
      end;
//    fwDataBaseName := TheIniDlg.Table1.DataBasename;
    fwDataBaseName := TheIniDlg.IniQuery.DataBasename; { RL 11/15/1999 }
    sl := TfwStringList.Create;
    try
      try
      if SqlIdExists(FwDatabaseName, st)
        then sl.Assign(GetSqlFromList(FwDatabaseName, st))
        else sl.add('[SQL Lib Entry Not Found]');
      except
        sl.add('[Error accessing SQL Lib]');
      end;
    if GetSqlCategory(sl) = scExec then
      StoredProcList.Add(GetStoredProcName(sl));
    SetPrinter(SQLSize,SQLStyle);
    AtX := AtX+XCoord(0.5);
    for loop := 0 to sl.count-1 do
      PrintString(sl[loop]);
    AtX := AtX-XCoord(0.5);
    finally
    sl.free;
    end;
  end;

  procedure WriteStoredProc(st:String);
  var sl : TfwStringList;
      loop : integer;
  begin
    if (st='') then exit;
    sl := TfwStringList.Create;
    try
    sfClearErrorMessage; { plr 11/4/98 }
    GetStoredProcText(st,sl);
    if sfErrorMessageWaiting  { plr 11/4/98 }
      then sl.add('[Error Reading Stored Procedure - '+sfLastErrorMessage+']')
    else if sl.count = 0
      then sl.add('[Stored Procedure Not Found]');
    SetPrinter(SQLSize,SQLStyle);
    AtX := AtX+XCoord(0.5);
    for loop := 0 to sl.count-1 do
      PrintString(sl[loop]);
    AtX := AtX-XCoord(0.5);
    finally
    sl.free;
    end;
  end;


  procedure WriteUDV(st:String);
  var FormImage: TBitmap;
      Info: PBitmapInfo;
      InfoSize: DWORD; {gns 13-Jan-1999}
      Image: Pointer;
      ImageSize: DWORD; {gns 13-Jan-1999}
      Bits: HBITMAP;
      DIBWidth, DIBHeight: Longint;
      PrintWidth, PrintHeight: Longint;
      aUDV : TsfUDV ;
      TheTag,TheDesc : String;


    function UDVExists(TheID:String; var TheTag,TheDesc:String):Boolean;
    var q : TVersaQuery;
    begin
      Result := false;
      q := TVersaQuery.Create(TheIniDlg);
      try
//      q.DataBaseName := TheIniDlg.Table1.DatabaseName;
      q.DataBaseName := TheIniDlg.IniQuery.DatabaseName; { RL 11/15/1999 }
      try
        OpenQueryWithParams(FwDatabaseName, q,SqlLibIdToString(slUDVGetDefinitionBlob),[TheID]);
        TheTag := q.FieldByName('UDV_TAG').Text; {CMH 2/27/98}
        TheDesc := q.FieldByName('UDV_DESC').Text; {CMH 2/27/98}
        Result := q.FieldByName('UDV_ID').Text <> '';
      except
      end;
      finally
      q.free;
      end;
    end;

    procedure WriteUDVDetails;
    var loop,loop2 : integer;
        sl2 : TfwStringList;
        SubSL : TSubStringsList;
    begin
      if not ExpandUDV then exit;
      AtX := AtX + xCoord(0.5); { indent an inch }
      sl2 := TfwStringList.Create;
      try
      SetPrinter(NormalSize,NormalStyle);
      if TheDesc <> ''
        then PrintString(TheTag+' - '+TheDesc)
        else PrintString(TheTag);


      if aUDV.ScrollBox.UdvControlType = uctScript then
        begin
          AtX := AtX + xCoord(0.25); { indent a 1/4 inch }
          PrintString('UDV Script');
        end;
      try

      if (aUDV.ComponentCount = 0) and (aUDV.ScrollBox.ComponentCount=0) then
        PrintString('    [Empty UDV]');

      for loop := 0 to aUDV.ComponentCount-1 do
        begin
          if aUDV.Components[loop] is TSFCustomSQLSource{TSFSQLSource} then
            with aUDV.Components[loop] as TSFCustomSQLSource{TSFSQLSource} do
              begin
                SetPrinter(NormalSize,NormalStyle);
                PrintString('SQL Source: '+Name);
                AtX := AtX+xCoord(0.5);
                try
                PrintString('SelectSqlId: '+SelectSQLID);
                WriteSQL(SelectSQLID);
                SetPrinter(NormalSize,NormalStyle);
                PrintString('DeleteSqlId: '+DeleteSQLID);
                WriteSQL(DeleteSQLID);
                SetPrinter(NormalSize,NormalStyle);
                PrintString('InputUDVId: '+InputUDVID);
                WriteUDV(InputUDVID);

                { drop commands }
                if DropCommands <> nil then
                  for loop2 := 0 to DropCommands.Count-1 do
                    begin
                      ParseStringToList(DropCommands[loop2],['~'],sl2,true);
                        if sl2.count = 3 then
                          begin
                            SetPrinter(NormalSize,NormalStyle);
                            PrintString('Drop Command UDV: '+sl2[1]+' ('+sl2[0]+')');
                            WriteUDV(sl2[1]);
                          end;
                    end;

                { other commands }
                if OtherCommands <> nil then
                  begin
                    SubSL := TSubStringsList.create;
                    try
                    OtherCommands.Convert;
                    for loop2 := 0 to OtherCommands.Count-1 do
                      begin
                        SubSL.AsNestedDataString := OtherCommands[loop2];
                        if SubSL.Values[sidAction] = sUDV then
                          begin
                            SetPrinter(NormalSize,NormalStyle);
                            PrintString('Other Command UDV: '+SubSL.Values[sidUDVId]+' ('+SubSL.Values[sidDesc]+')');
                            WriteUDV(SubSL.Values[sidUDVID]);
                          end;
                        if SubSL.Values[sidAction] = sBookmarkExpress then
                          begin
                            SetPrinter(NormalSize,NormalStyle);
                            if SubSL.Values[sidUpdateSql] <> sEmpty then
                              begin
                                PrintString('Other Command Bookmark Update: '+SubSL.Values[sidUpdateSql]+' ('+SubSL.Values[sidDesc]+')');
                                WriteSQL(SubSL.Values[sidUpdateSql]);
                              end;
                            if SubSL.Values[sidDeleteSql] <> sEmpty then
                              begin
                                PrintString('Other Command Bookmark Delete: '+SubSL.Values[sidDeleteSql]+' ('+SubSL.Values[sidDesc]+')');
                                WriteSQL(SubSL.Values[sidDeleteSql]);
                              end;
                          end;
                      end;
                    finally
                    SubSL.Free;
                    end;
                  end;

                finally
                AtX := AtX - xCoord(0.5);
                end;
              end;
        end;
      for loop := 0 to aUDV.ScrollBox.ComponentCount-1 do
        begin
          {20041114,plr: Handle udv scripts}
          If aUDV.ScrollBox.Components[loop] Is TScriptStatement Then
            with aUDV.ScrollBox.Components[loop] As TScriptStatement Do
              begin
                SetPrinter(NormalSize,NormalStyle);
                PrintString('  Statement: '+ScriptCaption+' - '+AtAGlance);
                AtX := AtX+xCoord(0.25);
                try

                If aUDV.ScrollBox.Components[loop] Is TSelectScriptStatement Then
                  WriteSQL((aUDV.ScrollBox.Components[loop] as TSelectScriptStatement).SqlId);

                If aUDV.ScrollBox.Components[loop] Is TExecScriptStatement Then
                  WriteSQL((aUDV.ScrollBox.Components[loop] as TExecScriptStatement).SqlId);

                If aUDV.ScrollBox.Components[loop] Is TUdvScriptStatement Then
                  WriteUDV((aUDV.ScrollBox.Components[loop] as TUdvScriptStatement).UDVId);

                finally
                AtX := AtX - xCoord(0.25);
                end;
              end;

          if aUDV.ScrollBox.Components[loop] is TSFSQLTransaction then
            with aUDV.ScrollBox.Components[loop] as TSFSQLTransaction do
              begin
                SetPrinter(NormalSize,NormalStyle);
                PrintString('SQL Transaction: '+Name);
                AtX := AtX+xCoord(0.5);
                try
                PrintString('InsertSqlId: '+InsertSQLID);
                WriteSQL(InsertSQLID);
                SetPrinter(NormalSize,NormalStyle);
                PrintString('UpdateSqlId: '+UpdateSQLID);
                WriteSQL(UpdateSQLID);

                { InputFields for lookup }

                if InputFieldsEditControlSSL <> nil then
                  for loop2 := 0 to InputFieldsEditControlSSL.Count-1 do
                    begin
                      if StringsMatch(InputFieldsEditControlSSL.SubStrings[loop2].Values[ecnCtrlType],DB_LOOKUP) Then
                        begin
                          SetPrinter(NormalSize,NormalStyle);
                          PrintString('DB Lookup Field SQL: '+InputFieldsEditControlSSL.SubStrings[loop2].Values[ecnSqlId]+' ('+InputFieldsEditControlSSL[loop2]+')');
                          WriteSQL(InputFieldsEditControlSSL.SubStrings[loop2].Values[ecnSqlId]);
                        end;
                    end;
                finally
                AtX := AtX - xCoord(0.5);
                end;
              end;
        end;
        finally
        if aUDV.ScrollBox.UdvControlType = uctScript then
          AtX := AtX - xCoord(0.25); { outdent a 1/4 inch }
        end;
      finally
      AtX := AtX - xCoord(0.5);
      sl2.free;
      end;
    end;

  begin
    PrintHeight := 0;
    PrintWidth := 0;
    if (st='') or (AnsiUpperCase(st)='@NA') or (AnsiUpperCase(st)='(N/A)') then exit;
    FullUdvIdList.Add(st); { we can call this again, since we have DupIgnore }
    if (PrintUDVOpt = 0) then exit;
    if WriteUDVAtEnd then
      begin
        UdvIdList.Add(st); { we can call this again, since we have DupIgnore }
        exit;
      end;
    FormImage := nil;

//    fwDataBaseName := TheIniDlg.Table1.DataBasename;
    fwDataBaseName := TheIniDlg.IniQuery.DataBasename;{ RL 11/15/1999 }

    sfClearErrorMessage; { plr 11/4/98 }

    { check to see if the UDV exists }
    if not UDVExists(st,TheTag,TheDesc) then
      begin
        SetPrinter(SQLSize,SQLStyle);
        PrintString('    [Missing UDV]');
        exit;
      end;

    aUDV := TsfUDV.create(TheIniDlg.DummyUDVPanel);
    try
    with aUDV do
      begin
        Parent := TheIniDlg.DummyUDVPanel;
//        UdvDatabaseName        :=  TheIniDlg.Table1.DataBasename;
        UdvDatabaseName        :=  TheIniDlg.IniQuery.DataBasename;
//        UdvDatabaseNameForEdit :=  TheIniDlg.Table1.DataBasename;
        UdvDatabaseNameForEdit :=  TheIniDlg.IniQuery.DataBasename; { RL 11/15/1999 }
        UdvDefinitionField := 'UDV_DEFINITION';
        UdvId  := st;
        ShowBorder := True ;
        try
        ShowParamsErrors := false; { we will want some way to capture these errors in the future }
        aUDV.LoadContents;
        if sfErrorMessageWaiting then { plr 11/4/98 }
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString('    [Error Reading UDV - '+sfLastErrorMessage+']');
            exit;
          end;
        except
          SetPrinter(SQLSize,SQLStyle);
          PrintString('    [Missing UDV]');
          exit;
        end;
        try
        ShowContents;
        Crop;
        if sfErrorMessageWaiting then { plr 11/4/98 }
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString('    [Error In UDV - '+sfLastErrorMessage+']');
            exit;
          end;
        TheIniDlg.DummyUDVPanel.height := 0;
        TheIniDlg.DummyUDVPanel.width := 0;
        TheIniDlg.DummyUDVPanel.visible := true;
        FormImage := GetControlImage(aUDV{ScrollBox}, []); {20030915,rtr: Refactoring}
        except
        on e:Exception do
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString(Format('    [Error in UDV: %s]',[e.Message]));
          end;
(*
        on e:ESQLLibError do
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString(Format('    [Error in UDV: %s]',[e.Message]));
          end;
        on e:ESQLNotFound do
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString(Format('    [Error in UDV: %s]',[e.Message]));
          end;
        else
          begin
            SetPrinter(SQLSize,SQLStyle);
            PrintString(Format('    [Error in UDV: %s]',['Unknown Error']));
          end;
*)
        end;
      end;

    if FormImage = nil then exit;
    try
    { now print the image }
    if PathForBitmaps <> '' then
      begin
        try
        FormImage.SaveToFile(PathForBitmaps+st+'.bmp');
        except
        MessageDlg('Error creating '+PathForBitmaps+st+'.bmp',mtError,[mbok],0);
        PathForBitmaps := '';
        end;
      end;
    if PrintToFile = '' then
      begin
        MoveDownOneLine;

          with Printer, Canvas do
          begin
            Bits := FormImage.Handle;
            GetDIBSizes(Bits, InfoSize, ImageSize);
            Info := AllocMem(InfoSize);
            try
              Image := AllocMem(ImageSize);
              try
                GetDIB(Bits, 0, Info^, Image^);
                with Info^.bmiHeader do
                begin
                  DIBWidth := biWidth;
                  DIBHeight := biHeight;
                end;
                case PrintUDVOpt of
                   1 : begin  { thumbnails }
                        PrintWidth := MulDiv(DIBWidth, GetDeviceCaps(Handle,
                            LOGPIXELSX), TheIniDlg.PixelsPerInch);
                        PrintHeight := MulDiv(DIBHeight, GetDeviceCaps(Handle,
                            LOGPIXELSY), TheIniDlg.PixelsPerInch);
                        PrintWidth := PrintWidth div 8;
                        PrintHeight := PrintHeight div 8;
                      end;
                  2 : begin
                        PrintWidth := MulDiv(DIBWidth, GetDeviceCaps(Handle,
                            LOGPIXELSX), TheIniDlg.PixelsPerInch);
                        PrintHeight := MulDiv(DIBHeight, GetDeviceCaps(Handle,
                            LOGPIXELSY), TheIniDlg.PixelsPerInch);
                        PrintWidth := PrintWidth div 3;
                        PrintHeight := PrintHeight div 3;
                      end;
                  3 : begin
                        PrintWidth := MulDiv(DIBWidth, GetDeviceCaps(Handle,
                            LOGPIXELSX), TheIniDlg.PixelsPerInch);
                        PrintHeight := MulDiv(DIBHeight, GetDeviceCaps(Handle,
                            LOGPIXELSY), TheIniDlg.PixelsPerInch);
                      end;
                end;
                if yCoord(SpaceLeft) < PrintHeight then
                  StartANewPage;
                StretchDIBits(Canvas.Handle, AtX+Xcoord(0.5), AtY, PrintWidth, PrintHeight, 0, 0,
                  DIBWidth, DIBHeight, Image, Info^, DIB_RGB_COLORS, SRCCOPY);
                AtY := AtY + PrintHeight;
                MoveDownOneLine;
              finally
                FreeMem(Image, ImageSize);
              end;
            finally
              FreeMem(Info, InfoSize);
            end;
          end;
      end;
    WriteUDVDetails;

    finally
    FormImage.Free;
    end;

    finally
    aUDV.Free;
    end;
  end;


  procedure WriteOutNode(Node:TIniTreeNode);
  var obj : TConfigObject;
      st : string;
      i,
      loop,
      loop2 : integer;
      sl,
      sl2 : TfwStringList;
  begin
    if node = nil then exit;
    sl := TfwStringList.Create;
    try
    while (Node <> nil) do
      begin
        if IncludeSiblings then { show status on full reports }
          begin
            NodeCounter := NodeCounter + 1;
            IniStatus.Label2.Caption := 'Processing entry '+IntToStr(NodeCounter)
                            +' of '+IntToStr(TheIniDlg.TreeView1.Items.Count);
          end;
        if IniStatus.UserCanceled
          then exit;
        Obj := TConfigObject(Node.Data);
        TheIniDlg.BuildDataStrings(node,Obj,sl);
        for i := 0 to sl.count-1 do
          begin
            st := sl[i];
            if st <> '' then
              begin
                for loop := 2 to (Node.Level-SkipIndentLevel) do
                  st := ' '+st;
                SetPrinter(NormalSize,NormalStyle);
                PrintStringWithDots(st);

                if (Obj.TypeName = 'STRINGEQUALSTRING') then
                  begin
                    if (pos('UDV ID',UpperCase(Obj.ObjectParams.Values['Left'])) > 0) then
                      begin
                        WriteUDV(Obj.ValueSL.Values['p1']);
                        WriteUDV(Obj.ValueSL.Values['p2']);
                      end;
                    if (pos('SQL ID',UpperCase(Obj.ObjectParams.Values['Left'])) > 0) then
                      begin
                        WriteSQL(Obj.ValueSL.Values['p1']);
                        WriteSQL(Obj.ValueSL.Values['p2']);
                      end;
                  end;
                if (Obj.TypeName = 'UDV') or
                   (Obj.TypeName = 'REFERENCEUDV') then
                  WriteUDV(Obj.ValueSL.Values['p1']);
                if ((Obj.TypeName = 'SQLID') or
                    (Obj.TypeName = 'REFERENCESQLID'))
                   and IncludeSQL then
                  WriteSQL(Obj.ValueSL.Values['p1']);
                if (Obj.TypeName = 'IDLEACTIONTYPE') and IncludeSQL
                    and (AnsiUpperCase(Obj.ValueSL.Values['p1']) = 'EXECSQL') then
                  WriteSQL(Obj.ValueSL.Values['p2']);
                if Obj.TypeName = 'UDVCONTROLTYPE' then
                  WriteUDV(Obj.ValueSL.Values['p2']);
                if (Obj.TypeName = 'OTHERCOMMANDTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p2']) = 'UDV') then
                  WriteUDV(Obj.ValueSL.Values['p4']);
                if (Obj.TypeName = 'TABTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p2']) = 'ACTIVATEUDV') then
                  WriteUDV(Obj.ValueSL.Values['p3']);
                if (Obj.TypeName = 'TABTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p5']) <> '') then
                  WriteSQL(Obj.ValueSL.Values['p5']);
                if (Obj.TypeName = 'DROPEVENTTYPE')   { plr 11/12/98 }
                    and (AnsiUpperCase(Obj.ValueSL.Values['p1']) <> '') then
                  begin
                    { UDV Id is the 2nd parameter of each "pX=desc~UDV~sourcenames }
                    loop2 := 1;
                    sl2 := TfwStringList.Create;
                    try
                    while Obj.ValueSL.Values['p'+IntToStr(loop2)] <> '' do
                      begin
                        ParseStringToList(Obj.ValueSL.Values['p'+IntToStr(loop2)],['~'],sl2,true);
                        if sl2.count > 1
                          then WriteUDV(sl2[1]);
                        loop2 := loop2 + 1;
                      end;
                    finally
                    sl2.free;
                    end;
                  end;
                WriteOutNode(TheIniDlg.FindFirstChild(Node));
              end;
          end;
        Node := TheIniDlg.FindNextSibling(Node);
      end;
    finally
    sl.free;
    end;
  end;

  procedure WriteTitle(st:String);
  begin
    RequireSpace(1.0);
    SetPrinter(TitleSize,TitleStyle);
    PrintString(st);
    MoveDown(0.2);
  end;

  procedure WriteSectionHeader(st:String);
  begin
    WriteTitle('['+st+']');
  end;

  procedure NowWriteSqlAtEnd;
  var loop : integer;
  begin
    if SqlIdList.Count = 0 then exit;
    WriteSqlAtEnd := false;
    MoveDown(0.5);
    WriteTitle('SQL Lib Entries');
    for loop := 0 to SqlIdList.Count-1 do
      begin
        MoveDown(0.2);
        RequireSpace(0.5);
        SetPrinter(CoreSQLSize,CoreSQLStyle);
        PrintString(SqlIdList[loop]);
        WriteSQL(SqlIdList[loop]);
      end;
  end;

  procedure NowWriteUDVAtEnd;
  var loop : integer;
  begin
    if UDVIdList.Count = 0 then exit;
    WriteUDVAtEnd := false;
    MoveDown(0.5);
    WriteTitle('UDV Entries');
    for loop := 0 to UDVIdList.Count-1 do
      begin
        MoveDown(0.2);
        RequireSpace(0.5);
        SetPrinter(CoreSQLSize,CoreSQLStyle);
        PrintString(UdvIdList[loop]);
        WriteUDV(UdvIdList[loop]);
      end;
  end;

  procedure WriteCoreSQLEntries;
  var sqlid : TSqlLibId;
      st : string;
  begin
    MoveDown(0.5);
    WriteTitle('Core SQL Lib Entries');
    for SqlID := low(TSqlLibID) to High(TSqlLibID) do
      begin
        MoveDown(0.2);
        RequireSpace(0.5);
        st := SqlLibIdToString(SqlID);
        SetPrinter(CoreSQLSize,CoreSQLStyle);
        PrintString(st);
        WriteSQL(st);
      end;
  end;

  procedure WriteComments(sl:TStrings);
  var loop : integer;
  begin
    if not IncludeComments then exit;
    SetPrinter(CommentSize,CommentStyle);
    AtX := AtX+XCoord(0.25);
    for loop := 0 to sl.count-1 do
      PrintString(';'+sl[loop]);
    AtX := AtX-XCoord(0.25);
  end;

  procedure WriteSQLIDList;
  var loop : integer;
  begin
    SetPrinter(TitleSize,TitleStyle);
    MoveDown(0.5);
    RequireSpace(1.5);
    PrintString('Referenced SQL Ids');
    MoveDown(0.1);
    SetPrinter(NormalSize,NormalStyle);
    PrintString('  (List of Sql Lib entries referenced in this printout)');
    MoveDown(0.2);
    for loop := 0 to FullSqlIdList.Count-1 do
      PrintString(FullSqlIdList[loop]);
  end;

  procedure WriteUDVIDList;
  var loop : integer;
  begin
    SetPrinter(TitleSize,TitleStyle);
    MoveDown(0.5);
    RequireSpace(1.5);
    PrintString('Referenced UDV Ids');
    MoveDown(0.1);
    SetPrinter(NormalSize,NormalStyle);
    PrintString('  (List of UDV entries referenced in this printout)');
    MoveDown(0.2);
    for loop := 0 to FullUDVIdList.Count-1 do
      PrintString(FullUDVIdList[loop]);
  end;


  procedure WriteStoredProcs;
  var loop : integer;
  begin
    if StoredProcList.Count = 0 then exit;
    MoveDown(0.5);
    RequireSpace(3.0);
    WriteTitle('Stored Procedures');
    for loop := 0 to StoredProcList.Count-1 do
      begin
        MoveDown(0.4);
        RequireSpace(1.0);
        SetPrinter(CoreSQLSize,CoreSQLStyle);
        PrintString(StoredProcList[loop]);
        WriteStoredProc(StoredProcList[loop]);
      end;
  end;

var Node : TIniTreeNode;
    sl2 : TfwStringList;
begin
  if PrintTofile <> '' then
    begin
      AssignFile(PrintFile,PrintToFile);
      {$I-} rewrite(Printfile); {$I+}
      if IoResult <> 0 then
        begin
          sfMessageDlg('Error creating output file: '+PrintToFile,MtError,[mbok],0);
          exit;
        end;
    end;
  Screen.Cursor := crHourglass;
  IniStatus := TIniStatusWin.Create(TheIniDlg);
  IniStatus.Label1.Caption := '';
  IniStatus.Label2.Caption := '';
  UdvIdList := TfwStringList.Create;
  SqlIdList := TfwStringList.Create;
  StoredProcList := TfwStringList.Create;
  FullUdvIdList := TfwStringList.Create;
  FullSqlIdList := TfwStringList.Create;
  sfSilentErrors := true; { plr 11/4/98 }
  try
  UdvIdList.Sorted := true;
  UdvIdList.Duplicates := dupIgnore;
  SqlIdList.Sorted := true;
  SqlIdList.Duplicates := dupIgnore;
  StoredProcList.Sorted := true;
  StoredProcList.Duplicates := dupIgnore;
  FullUdvIdList.Sorted := true;
  FullUdvIdList.Duplicates := dupIgnore;
  FullSqlIdList.Sorted := true;
  FullSqlIdList.Duplicates := dupIgnore;

  NodeCounter := 0;
  TheIniDlg.StoreCurrentPage;
  Node := FromNode;
  sl2 := TfwStringList.Create;
  if (TheIniDlg.GetParent(Node) = nil) or (Node.Level < 2) then { starting at section }
    SkipIndentLevel := 0
 else
    SkipIndentLevel := (Node.Level-2);
  if PrintToFile = '' then
    begin
      Printer.BeginDoc;
      with Printer.Canvas.Font do
        begin
          Name := 'Courier New';
          PixelsPerInch := GetDeviceCaps(Printer.Canvas.Handle,LOGPIXELSY);
                          {plr-from Borland TI 3211 - Assuring proper scaling}
          Style := [];
          Size := 10;
        end;
      PixelsPerInchVertical := GetDeviceCaps( Printer.Handle,LOGPIXELSY );
      PixelsPerInchHorizontal := GetDeviceCaps( Printer.Handle,LOGPIXELSX );

      OnPage := 0;
    end
  else
    begin
      PixelsPerInchVertical := 6;
      PixelsPerInchHorizontal := 8;
      IniStatus.Label1.Caption := 'Writing to file: '+PrintToFile;
      OnPage := 1;
    end;
  AtY := YCoord(TopMargin);
  AtX := XCoord(LeftMargin);
  try

  IniStatus.Label2.Caption := 'Printing Ini Record...';
  IniStatus.Top := IniStatus.Top div 2;
  IniStatus.Show;
  SetPrinter(TitleSize,TitleStyle);
  PrintString('Ini ID: '+TheIniDlg.IniIdEdit.Text);  { RL 11/18/1999 }
  SetPrinter(NormalSize,NormalStyle);
  PrintString('Database:  '+TheIniDlg.CfgFrame.ConnectionName);
  MoveDown(0.2);


    while (Node <> nil) do
      begin
        Application.ProcessMessages;
        if IniStatus.UserCanceled
          then exit;
        if Node <> FromNode then
          MoveDown(0.5);
        if TheIniDlg.GetParent(FromNode) = nil then
          begin
            RequireSpace(1.0);
            NodeCounter := NodeCounter + 1;
            WriteSectionHeader(Node.Text);
            TheIniDlg.Comments.ReadStrings('Comments.['+Node.Text+']',sl2);
            WriteComments(sl2);
          end
        else
          WriteOutNode(Node);
        WriteOutNode(TheIniDlg.FindFirstChild(Node));
        if IncludeSiblings
          then Node := TheIniDlg.FindNextSibling(Node)
          else Node := nil;
      end;
    if WriteUDVAtEnd then { write UDV first, so its SQL will write at end }
      begin
        IniStatus.Label2.Caption := 'Printing UDVs...';
        NowWriteUDVAtEnd;
      end;
    if WriteSqlAtEnd then
      begin
        IniStatus.Label2.Caption := 'Printing SQL...';
        NowWriteSqlAtEnd;
      end;
    if PrintCoreSQL then
      begin
        IniStatus.Label2.Caption := 'Printing Core SQL...';
        WriteCoreSQLEntries;
      end;
    if ListSQLIds then
      begin
        IniStatus.Label2.Caption := 'Printing SQL Id List...';
        WriteSQLIDList;
      end;
    if ListUDVIds then
      begin
        IniStatus.Label2.Caption := 'Printing UDV Id List...';
        WriteUDVIDList;
      end;
    if WriteStoredProcsAtEnd then
      begin
        IniStatus.Label2.Caption := 'Printing Stored Procedures...';
        WriteStoredProcs;
      end;

  finally
  sl2.free;
  IniStatus.Hide;
  if PrintToFile = '' then
    begin
      if IniStatus.UserCanceled
        then Printer.Abort
        else Printer.EndDoc;
    end;
  end;
  finally
  sfSilentErrors := false; { plr 11/4/98 }
  UdvIdList.free;
  SqlIdList.free;
  StoredProcList.Free;
  FullUdvIdList.free;
  FullSqlIdList.free;
  if PrintTofile <> '' then
    CloseFile(PrintFile);
  IniStatus.free;
  Screen.Cursor := crDefault;
  end;
end;


procedure ExportIniLibLocalizationTable(TheIniDlg: TIniLibMaintDlg; FromNode:TIniTreeNode; FileName: string);
var
  NodeCounter : LongInt;
  IniStatus : TIniStatusWin;
  SkipIndentLevel : integer;

  function GetParentQualifiers(Node:TIniTreeNode): string;

    procedure AddParentQualifier(aNode: TIniTreeNode);
    begin
      if aNode <> nil then
        begin
          if result <> ''
            then result := aNode.Text+'.'+result
            else result := aNode.Text;
          if aNode.Parent <> nil
            then AddParentQualifier(aNode.Parent);
        end;
    end;

  begin
    result := '';
    AddParentQualifier(Node);
  end;

  procedure WriteOutNode(Node:TIniTreeNode);
  var obj : TConfigObject;
      ParentNodeText, PropName, Value, st, S : string;
      i,
      loop,
      loop2 : integer;
      sl,
      sl2 : TfwStringList;
  begin
    if node = nil then exit;
    sl := TfwStringList.Create;
    try
    while (Node <> nil) do
      begin
        NodeCounter := NodeCounter + 1;
        IniStatus.Label2.Caption := 'Processing entry '+IntToStr(NodeCounter)
                            +' of '+IntToStr(TheIniDlg.TreeView1.Items.Count);
        if IniStatus.UserCanceled
          then exit;
        Obj := TConfigObject(Node.Data);
        TheIniDlg.BuildDataStrings(node,Obj,sl);
        for i := 0 to sl.count-1 do
          begin
            st := sl[i];
            if st <> '' then
              begin
                if (Node.Parent <> nil)
                  then ParentNodeText := Node.Parent.Text
                  else ParentNodeText := '';
                if Among(ParentNodeText,['SelectedFields','Tabs','ListGroups','OtherCommands']) then
                  begin
                    POAddClassPropValue(GetParentQualifiers(Node.Parent.Parent), ParentNodeText, st, '');
                  end
                 else
                  begin
                    PropName := GetListItemName(st);
                    Value := GetListItemValue(st);
                    if (Value <> '')
                       and among(PropName,[
                                     'Caption',            //
                                     'Hint',
                                     'ControlHint',
                                     'DescriptionCaption', //
                                     'RptTagCaption',      //
                                     'DocumentCaption',    //
                                     'ToolCaption',        //
                                     'Description',        //
                                     'NavToolbarCaption',  //
                                     'PrintHeader',        //
                                     'HistoryText',        //
                                     'DisplayLabel',       //
                                     'Line1Text',          //
                                     'Line2Text',          //
                                     'Line3Text']) then    //
                       begin
                         if Node.Parent <> nil
                           then S := GetParentQualifiers(Node.Parent)
                           else S := '';
                         POAddClassPropValue(S, PropName, Value, '');
                       end;
                     end;
                (*
                if (Obj.TypeName = 'STRINGEQUALSTRING') then
                  begin
                    if (pos('UDV ID',UpperCase(Obj.ObjectParams.Values['Left'])) > 0) then
                      begin
                        WriteUDV(Obj.ValueSL.Values['p1']);
                        WriteUDV(Obj.ValueSL.Values['p2']);
                      end;
                    if (pos('SQL ID',UpperCase(Obj.ObjectParams.Values['Left'])) > 0) then
                      begin
                        WriteSQL(Obj.ValueSL.Values['p1']);
                        WriteSQL(Obj.ValueSL.Values['p2']);
                      end;
                  end;
                if (Obj.TypeName = 'UDV') or
                   (Obj.TypeName = 'REFERENCEUDV') then
                  WriteUDV(Obj.ValueSL.Values['p1']);
                if ((Obj.TypeName = 'SQLID') or
                    (Obj.TypeName = 'REFERENCESQLID'))
                   and IncludeSQL then
                  WriteSQL(Obj.ValueSL.Values['p1']);
                if (Obj.TypeName = 'IDLEACTIONTYPE') and IncludeSQL
                    and (AnsiUpperCase(Obj.ValueSL.Values['p1']) = 'EXECSQL') then
                  WriteSQL(Obj.ValueSL.Values['p2']);
                if Obj.TypeName = 'UDVCONTROLTYPE' then
                  WriteUDV(Obj.ValueSL.Values['p2']);
                if (Obj.TypeName = 'OTHERCOMMANDTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p2']) = 'UDV') then
                  WriteUDV(Obj.ValueSL.Values['p4']);
                if (Obj.TypeName = 'TABTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p2']) = 'ACTIVATEUDV') then
                  WriteUDV(Obj.ValueSL.Values['p3']);
                if (Obj.TypeName = 'TABTYPE')
                    and (AnsiUpperCase(Obj.ValueSL.Values['p5']) <> '') then
                  WriteSQL(Obj.ValueSL.Values['p5']);
                if (Obj.TypeName = 'DROPEVENTTYPE')   { plr 11/12/98 }
                    and (AnsiUpperCase(Obj.ValueSL.Values['p1']) <> '') then
                  begin
                    { UDV Id is the 2nd parameter of each "pX=desc~UDV~sourcenames }
                    loop2 := 1;
                    sl2 := TfwStringList.Create;
                    try
                    while Obj.ValueSL.Values['p'+IntToStr(loop2)] <> '' do
                      begin
                        ParseStringToList(Obj.ValueSL.Values['p'+IntToStr(loop2)],['~'],sl2,true);
                        if sl2.count > 1
                          then WriteUDV(sl2[1]);
                        loop2 := loop2 + 1;
                      end;
                    finally
                    sl2.free;
                    end;
                  end;
                *)
                WriteOutNode(TheIniDlg.FindFirstChild(Node));
              end;
          end;
        Node := TheIniDlg.FindNextSibling(Node);
      end;
    finally
    sl.free;
    end;
  end;

var Node : TIniTreeNode;
    sl2 : TfwStringList;
begin
(*
  if FileExists(FileName) then
    begin
      if sfMessageDlg(Format('Overwrite existing file %s?',[FileName]),mtConfirmation,[mbOk,mbCancel],0) <> mrOk
        then exit;
    end;
*)    
  BeginGnuExport;
  Screen.Cursor := crHourglass;
  IniStatus := TIniStatusWin.Create(TheIniDlg);
  IniStatus.Label1.Caption := '';
  IniStatus.Label2.Caption := '';
  sfSilentErrors := true; { plr 11/4/98 }
  try
    NodeCounter := 0;
    TheIniDlg.StoreCurrentPage;
    Node := FromNode;
    sl2 := TfwStringList.Create;
    if (TheIniDlg.GetParent(Node) = nil) or (Node.Level < 2) then { starting at section }
       SkipIndentLevel := 0
      else
       SkipIndentLevel := (Node.Level-2);
    IniStatus.Label1.Caption := 'Writing to file: '+FileName;
    try
      IniStatus.Label2.Caption := 'Printing Ini Record...';
      IniStatus.Top := IniStatus.Top div 2;
      IniStatus.Show;
//      PrintString('Ini ID: '+TheIniDlg.IniIdEdit.Text);  { RL 11/18/1999 }
//      PrintString('Database:  '+TheIniDlg.CfgFrame.ConnectionName);

      while (Node <> nil) do
        begin
          Application.ProcessMessages;
          if IniStatus.UserCanceled
            then exit;
          if TheIniDlg.GetParent(FromNode) = nil then
            begin
              NodeCounter := NodeCounter + 1;
              if SameText(Node.Text,'BlockDefinition') then
                begin
                  Node := TheIniDlg.FindNextSibling(Node);
                  continue;
                end;
            end
          else
            WriteOutNode(Node);
          WriteOutNode(TheIniDlg.FindFirstChild(Node));
          Node := TheIniDlg.FindNextSibling(Node)
        end;
    finally
      sl2.free;
      IniStatus.Hide;
    end;
  finally
    sfSilentErrors := false; { plr 11/4/98 }
    IniStatus.free;
    EndGnuExport;
    Screen.Cursor := crDefault;
  end;
  POSaveResultsToFile(FileName);
  if POErrors.Count <> 0
    then TextScrollStringList('Export Localization Errors', POErrors);
end;

end.
