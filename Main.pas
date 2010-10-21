{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit Main;
{$I PRJDefines.inc}
Interface

uses
//    Qmemory,
{$IFDEF DEBUG}
    DebugLog, 
{$ENDIF}
    Windows,
    Classes,
    SysUtils,
    Plugin,
    FarAPI,
    PluginLng,
    FileUtils,
    FileSystemObjects,
    MainDialogs;

const
     PPIF_GROUP = 1;

type
    TFarPlugin = class
    private
      FMainDialog: TMainDialog;
//      FCurrentPanelItem: Integer;
      FFileGroupList: TFileGroupList;
      FFlagStop: Boolean;
      FFlagPressBreak: Boolean;
//      FFlagInProcess: Boolean;
//      FFlagUseAnotherPanel: Boolean;
      FIncludeFileMasks, FExcludeDirMasks, FSearchPaths: TStringList;
    protected
      function IsBreak: Boolean;
      procedure FindDupFile(Cat: String);
      function FindDupDir(Cat: String): TDirectoryObject;
      function ProcessAllDisks: Integer;
    public
      constructor Create;
      destructor Destroy; Override;
      procedure GetOpenPluginInfo(var aInfo: TOpenPluginInfo);
      function  GetFindData(var aPanelItems: PPluginPanelItemArray;
                            var aItemsNumber: Integer; opMode: Integer): Integer;
      procedure FreeFindData(aPanelItems: PPluginPanelItemArray;
                             aItemsNumber: integer);
      function ProcessEvent(aEvent: Integer; aParam: pointer): Integer;
      function ProcessKey(aKey: Integer; aControlState: UINT): Integer;
      procedure ProcessRemoveKey;
    end;

   procedure GetPluginInfo(var aInfo: TPluginInfo); stdcall;

Implementation

constructor TFarPlugin.Create;
begin
  inherited Create;
  FFileGroupList:=Nil;
//  FCurrentPanelItem:=-1;
//  FFlagInProcess:=False;
//  FFlagUseAnotherPanel:=False;
{
  FMainDialog:=TMainDialog.Create;
  FMainDialog.Show;
}
end;

destructor TFarPlugin.Destroy;
begin
  if Assigned(FFileGroupList) then FFileGroupList.Free;
{
  FMainDialog.Free;
}
  inherited Destroy;
end;

function TFarPlugin.IsBreak: Boolean;
begin
  Result:=FFlagStop;
  if (not Result) and (FFlagPressBreak or CheckForEsc) then
  begin
    FFlagStop:=True;
    Result:=True;
  end;
end;

var
  PanelModes: packed array[0..0] of TPanelMode =
   ((ColumnTypes:        'N';
     ColumnWidths:       '0';
     ColumnTitles:       nil;
     FullScreen:         integer(False);
     DetailedStatus:     integer(True);
     AlignExtensions:    integer(False);
     CaseConversion:     integer(False);
     StatusColumnTypes:  nil;
     StatusColumnWidths: nil)
   );
  KeyBarTitles: TKeyBarTitles;

procedure TFarPlugin.GetOpenPluginInfo(var aInfo: TOpenPluginInfo);
begin
  ZeroMemory(@aInfo, SizeOf(TOpenPluginInfo));
  ZeroMemory(@KeyBarTitles, SizeOf(TKeyBarTitles));
  KeyBarTitles.Titles[6]:=GetMsg(msgRemove);
  KeyBarTitles.AltShiftTitles[2]:=GetMsg(msgMode);
  with aInfo do
  begin
       StructSize:=SizeOf(TOpenPluginInfo);
       Flags:=OPIF_USEHIGHLIGHTING or OPIF_ADDDOTS or OPIF_REALNAMES;
       PanelModesArray:=@PanelModes;
       PanelModesNumber:=1;
       StartPanelMode:=$30;
       StartSortMode:=SM_UNSORTED;
       KeyBar:=@KeyBarTitles;
  end;
end;

procedure TFarPlugin.FindDupFile(Cat: String);
var
  hFindFile: THandle;
  FindData: TWin32FindData;
  I: Integer;
  Found: Bool;
begin
  if Assigned(FExcludeDirMasks) then
  begin
    I:=0;
    while (I<FExcludeDirMasks.Count) and
          (CmpName(PChar(FExcludeDirMasks.Strings[I]),
           PChar(Cat+StrPas(@FindData.cFileName)+'\'),
           False)=False) do Inc(I);
    if I<>FExcludeDirMasks.Count then Exit;
  end;

  hFindFile:=FindFirstFile(PChar(Cat+'*'), FindData);
  if hFindFile<>INVALID_HANDLE_VALUE then
    begin
      Found:=True;
      while (Found<>False) and (not isBreak) do
      begin
        if (FindData.dwFileAttributes and faDirectory)<>0 then
          begin
            if (StrPas(@FindData.cFileName)<>'.') and
               (StrPas(@FindData.cFileName)<>'..') then
              FindDupFile(Cat+StrPas(@FindData.cFileName)+'\');
          end
        else
          begin
            if Assigned(FIncludeFileMasks) then
              begin
                I:=0;
                while (I<FIncludeFileMasks.Count) and
                      (CmpName(PChar(FIncludeFileMasks.Strings[I]),
                       @FindData.cFileName,
                       False)=False) do Inc(I);
                if I<>FIncludeFileMasks.Count then
                begin
                  Move(FindData.cFileName,
                       FindData.cFileName[Length(Cat)],
                       StrLen(FindData.cFileName)+1);
                  Move(Cat[1],
                       FindData.cFileName,
                       Length(Cat));
                  FFileGroupList.Add(TFileObject.Create(FindData));
                end;
              end
            else
              begin
                Move(FindData.cFileName,
                     FindData.cFileName[Length(Cat)],
                     StrLen(FindData.cFileName)+1);
                Move(Cat[1],
                     FindData.cFileName,
                     Length(Cat));
                FFileGroupList.Add(TFileObject.Create(FindData));
              end;
          end;
        Found:=FindNextFile(hFindFile, FindData);
      end;
      Windows.FindClose(hFindFile);
    end;
end;

function TFarPlugin.FindDupDir(Cat: String): TDirectoryObject;
var
  hFindFile: THandle;
  FindData: TWin32FindData;
  I: Integer;
  Found: Bool;
  tmpDirectoryObject: TDirectoryObject;
begin
  Result:=nil;

  if Assigned(FExcludeDirMasks) then
  begin
    I:=0;
    while (I<FExcludeDirMasks.Count) and
          (CmpName(PChar(FExcludeDirMasks.Strings[I]),
           PChar(Cat),
           False)=False) do Inc(I);
    if I<>FExcludeDirMasks.Count then Exit;
  end;
{
  Move(Cat[1], FindData.cFileName, Length(Cat));
  FindData.cFileName[Length(Cat)]:=#0;
  FindData.nFileSizeLow:=0;
  FindData.dwFileAttributes:=GetFileAttributes(FindData.cFilename);
}

  SetLastError(0);
  hFindFile:=FindFirstFile(PChar(Cat+'*'), FindData);
  if GetLastError=0 then
    begin
      if hFindFile<>INVALID_HANDLE_VALUE then
	if ((FindData.dwFileAttributes and faDirectory)<>0) and (StrPas(@FindData.cFileName)='.') then
	begin
  	  Move(Cat[1], FindData.cFileName, Length(Cat));
          FindData.cFileName[Length(Cat)]:=#0;
  	  Result:=TDirectoryObject.Create(FindData);
          Found:=FindNextFile(hFindFile, FindData);
          while (Found<>False) and (not isBreak) do                                   
          begin                                                                       
            if (FindData.dwFileAttributes and faDirectory)<>0 then                    
              begin                                                                   
                if (StrPas(@FindData.cFileName)<>'.') and                             
                   (StrPas(@FindData.cFileName)<>'..') then                           
                begin                                                                 
                  tmpDirectoryObject:=FindDupDir(Cat+StrPas(@FindData.cFileName)+'\');
                  if Assigned(tmpDirectoryObject) then                                
                  begin                                                               
//                    tmpDirectoryObject.SetFileSystemRecord(FindData);                 
                    Result.AddMember(tmpDirectoryObject);                             
                  end;                                                                
                end;                                                                  
              end                                                                     
            else                                                                      
              begin                                                                   
                if Assigned(FIncludeFileMasks) then                                   
                  begin                                                               
                    I:=0;                                                             
                    while (I<FIncludeFileMasks.Count) and                             
                          (CmpName(PChar(FIncludeFileMasks.Strings[I]),               
                           @FindData.cFileName,                                       
                           False)=False) do Inc(I);                                   
                    if I<>FIncludeFileMasks.Count then                                
                    begin                                                             
                      Move(FindData.cFileName,                                        
                           FindData.cFileName[Length(Cat)],                           
                           StrLen(FindData.cFileName)+1);                             
                      Move(Cat[1],                                                    
                           FindData.cFileName,                                        
                           Length(Cat));                                              
                      Result.AddMember(TFileObject.Create(FindData));                 
                    end;                                                              
                  end                                                                 
                else                                                                  
                  begin                                                               
                    Move(FindData.cFileName,                                          
                         FindData.cFileName[Length(Cat)],                             
                         StrLen(FindData.cFileName)+1);                               
                    Move(Cat[1],                                                      
                         FindData.cFileName,                                          
                         Length(Cat));                                                
                    Result.AddMember(TFileObject.Create(FindData));                   
                  end;                                                                
              end;                                                                    
            Found:=FindNextFile(hFindFile, FindData);                                 
          end;                                                                        
          Windows.FindClose(hFindFile);                                               
        end;
      FFileGroupList.Add(Result);
    end
  else
    FreeAndNil(Result);
end;

function TFarPlugin.ProcessAllDisks: Integer;
var
   Drivers: array[0..255] of Char;
   Index: Byte;
   RootDirectory: String;
   I: LongInt;
begin
     if FileExists(GetPluginPath+'exclude.txt') then
       begin
         FExcludeDirMasks:=TStringList.Create;
         FExcludeDirMasks.LoadFromFile(GetPluginPath+'exclude.txt');
       end
     else
       FExcludeDirMasks:=Nil;

     if FileExists(GetPluginPath+'include.txt') then
       begin
         FIncludeFileMasks:=TStringList.Create;
         FIncludeFileMasks.LoadFromFile(GetPluginPath+'include.txt');
         if FIncludeFileMasks.Count<1 then FreeANDNil(FIncludeFileMasks);
       end
     else
       FIncludeFileMasks:=Nil;

     if FileExists(GetPluginPath+'SearchPaths.txt') then
       begin
         FSearchPaths:=TStringList.Create;
         FSearchPaths.LoadFromFile(GetPluginPath+'SearchPaths.txt');
         if FSearchPaths.Count>0 then
         for I:=0 to FSearchPaths.Count-1 do
         begin
           if FileExists(GetPluginPath+'FindDupDir.flg') then
             FindDupDir(PChar(FSearchPaths[I]))
           else
             FindDupFile(PChar(FSearchPaths[I]));
         end;
         FSearchPaths.Free;
       end
     else
       begin
         GetLogicalDriveStrings(SizeOf(Drivers), @Drivers);
         Index:=0;
         RootDirectory:=StrPas(Drivers);
         while (Length(RootDirectory)>0) and (not isBreak) do
         begin
           if FileExists(GetPluginPath+'FindDupDir.flg') then
             FindDupDir(RootDirectory)
           else
             FindDupFile(RootDirectory);

(*
              case GetDriveType(PChar(@RootDirectory[1])) of
//                DRIVE_REMOVABLE: Writeln(F, 'сменный)');
                DRIVE_FIXED,
                DRIVE_CDROM:     begin
                                   Scan(RootDirectory);
                                 end;
                DRIVE_REMOTE:    Writeln(F, 'сетевой)');
                DRIVE_CDROM:     Writeln(F, 'CD-ROM)');
                DRIVE_RAMDISK:   Writeln(F, 'RAM)');
              end;
*)
              Index:=Index+Length(RootDirectory)+1;
              RootDirectory:=StrPas(@Drivers[Index]);
         end;
       end;
//     FindDupDir('C:\2\');
     FIncludeFileMasks.Free;
     FExcludeDirMasks.Free;
     Result:=Integer(True);
end;

function TFarPlugin.GetFindData(var aPanelItems: PPluginPanelItemArray;
                          var aItemsNumber: integer; opMode: integer): Integer;
var
  I, J, Index, Gr: LongInt;
  hScreen: THandle;
begin
{$IFDEF UseExcept}
  try
{$ENDIF UseExcept}
    hScreen:=SaveScreen(0, 0, -1, -1);
    try
      Message(0, nil,
              [Integer(msgPluginMenuString),
               Integer(msgCreateFileList)],
               0);
      if FFileGroupList=nil then
        begin
          FFlagStop:=False;
          FFlagPressBreak:=False;
          FFileGroupList:=TFileGroupList.Create;
          Result:=ProcessAllDisks;
        end
      else
        begin
{$IFDEF FullRescan}
         if FFlagStop then   // если предыдущий поиск был прерван пользователем,
            begin            // то полное пересканирование,
              FFlagStop:=False;
              FFlagPressBreak:=False;
              FFileGroupList.Clear;
              Result:=ProcessAllDisks;
            end
          else               // иначе проверка валидности информации
            begin
{$ENDIF FullRescan}
              FFlagStop:=False;
              FFlagPressBreak:=False;
{$IFDEF AUTO_VALIDATE}
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "FFileGroupList.Validate"', 2);
{$ENDIF}

              FFileGroupList.Validate;

{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "FFileGroupList.Validate"', -2);
{$ENDIF}

{$ELSE AUTO_VALIDATE}

{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "FFileGroupList.Pack"', 2);
{$ENDIF}
              FFileGroupList.Pack;

{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "FFileGroupList.Pack"', -2);
{$ENDIF}

{$ENDIF AUTO_VALIDATE}

              Result:=Integer(True);
{$IFDEF FullRescan}
            end;
{$ENDIF FullRescan}
        end;

//      FFileGroupList.Pack;
{$IFDEF SORT_PANEL}
      FFileGroupList.Sort;
{$ENDIF}
      aItemsNumber:=FFileGroupList.GroupedFilesCount+FFileGroupList.GroupsCount;
      GetMem(aPanelItems, SizeOf(TPluginPanelItem)*aItemsNumber);
      ZeroMemory(aPanelItems, SizeOf(TPluginPanelItem)*aItemsNumber);
      Index:=0;
      Gr:=1;
      for I:=0 to FFileGroupList.GroupsCount-1 do
      begin
{
        if FFileGroupList.Items[I].Count>1 then
        begin
}
          With aPanelItems^[Index] do
          begin
{!!!}
            UserData:=DWORD(FFileGroupList.Items[I]);
            Flags:=PPIF_GROUP;
{!!!}
            With FindData do
            begin
              dwFileAttributes:=FILE_ATTRIBUTE_DIRECTORY;
              StrCopy(PChar(@cFileName[0]), PChar('['+StrPas(GetMsg(msgGroup))+' '
                      +IntToStr(Gr)+']'));
              Inc(Gr);
              Inc(Index);
            end;
          end;
          for J:=0 to FFileGroupList.Items[I].Count-1 do
          With aPanelItems^[Index] do
          begin
{!!!}
            UserData:=DWORD(FFileGroupList.Items[I].Items[J]);
{!!!}
            FFileGroupList.Items[I].Items[J].GetFileSystemRecord(FindData);
            Inc(Index);
          end;
//        end;
      end;
    finally
      RestoreScreen(hScreen);
    end;
{$IFDEF UseExcept}
  except
    Result:=Integer(False)
 end;
{$ENDIF UseExcept}
end;

procedure TFarPlugin.FreeFindData(aPanelItems: PPluginPanelItemArray;
                                  aItemsNumber: integer);
begin
  FreeMem(aPanelItems);
end;

{.$DEFINE DEBUG_ANOTHERPANEL}
function  TFarPlugin.ProcessEvent(aEvent: Integer; aParam: pointer): Integer;
{
var
   PanelInfo: TPanelInfo;
}
//   PanelItem: TPluginPanelItem;
{$IFDEF DEBUG_ANOTHERPANEL}
   F: Text;
{$ENDIF DEBUG_ANOTHERPANEL}
begin
  Result:=Integer(False);
  case aEvent of
    FE_BREAK: FFlagPressBreak:=True;
{
    FE_REDRAW: begin
      if not FFlagInProcess then
      begin
        FFlagInProcess:=True;
        if (Control(THandle(self), FCTL_GETPANELINFO, @PanelInfo)<>0) and
           (PanelInfo.CurrentItem>0) and
           (PanelInfo.CurrentItem<=PanelInfo.ItemsNumber) and
           (PanelInfo.SelectedItemsNumber>0) and
           ((PanelInfo.PanelItems^[PanelInfo.CurrentItem].Flags and PPIF_GROUP)=0) then
        begin
          if not TFileSystemObject(PanelInfo.PanelItems^
             [PanelInfo.CurrentItem].UserData).IsValid then
          begin
            Control(THandle(self), FCTL_UPDATEPANEL, nil);
            Control(THandle(self), FCTL_REDRAWPANEL, nil);
            if not ((Control(THandle(self), FCTL_GETPANELINFO, @PanelInfo)<>0) and
               (PanelInfo.SelectedItemsNumber>0)) then
            begin
              FFlagInProcess:=False;
              Exit;
            end;
          end;
          if FFlagUseAnotherPanel and PanelInfo.Focus then
          begin
            // показ содержимого каталога под курсором на противоположной панели
            with PanelInfo.PanelItems^[PanelInfo.CurrentItem] do
//            if Flags and PPIF_GROUP) = 0 and
            begin
              if (FindData.dwFileAttributes and faDirectory) = 0
              then
                Control(THandle(self), FCTL_SETANOTHERPANELDIR,
                        PChar(ExtractFileDir(StrPas(@FindData.cFileName))))
              else
                Control(THandle(self), FCTL_SETANOTHERPANELDIR, @FindData.cFileName);

//              Control(THandle(self), FCTL_UPDATEANOTHERPANEL, nil);
              Control(THandle(self), FCTL_REDRAWANOTHERPANEL, nil);
            end;
          end;
        end;
        FFlagInProcess:=False;
      end;
    end;
}
  end;
end;

function TFarPlugin.ProcessKey(aKey: Integer; aControlState: UINT): Integer;
begin
  {скрытие: скрываем текущую позицию и прерываем обработку}
  Result:=Integer(False);
  if (aControlState=0) and (aKey=VK_F7) then
  begin
    ProcessRemoveKey;
    Control(THandle(self), FCTL_UPDATEPANEL, nil);
    Control(THandle(self), FCTL_REDRAWPANEL, nil);
    Result:=Integer(True);
  end;

  {при перемещении файла: скрываем текущую позицию и возвращаем обработку FAR}
  if (aControlState=0) and (aKey=VK_F6) then
  begin
    ProcessRemoveKey;
    Result:=Integer(False);
  end;

  {при удалении файла: скрываем текущую позицию и возвращаем обработку FAR}
  if (aControlState=0) and (aKey=VK_F8) then
  begin
    ProcessRemoveKey;
    Result:=Integer(False);
  end;

  if (aControlState=PKF_SHIFT or PKF_ALT) and (aKey=VK_F3) then
  begin
    FFileGroupList.ChangeMode;
    Control(THandle(self), FCTL_UPDATEPANEL, nil);
    Control(THandle(self), FCTL_REDRAWPANEL, nil);
    Result:=Integer(True);
  end;

{$IFDEF VALIDATE}
  if (aControlState=PKF_CONTROL) and (aKey=Ord('R')) then
  begin
    FFileGroupList.Validate;
    Control(THandle(self), FCTL_UPDATEPANEL, nil);
    Control(THandle(self), FCTL_REDRAWPANEL, nil);
    Result:=Integer(True);
  end;
{$ENDIF VALIDATE}

  if (aControlState=PKF_SHIFT or PKF_ALT) and (aKey=VK_F1) then
  begin
    FMainDialog:=TMainDialog.Create;
    FMainDialog.Show;
    FMainDialog.Free;
    Result:=Integer(True);
  end;
{
  if (aControlState=(PKF_CONTROL or PKF_ALT)) and (aKey=Ord('Q')) then
  begin
    FFlagUseAnotherPanel:=not FFlagUseAnotherPanel;
    Result:=Integer(True);
  end;
}
end;

procedure TFarPlugin.ProcessRemoveKey;
var
   PanelInfo: TPanelInfo;
   I: LongInt;
begin
  Control(THandle(self), FCTL_GETPANELINFO, @PanelInfo);
  with PanelInfo do
    for I:=0 to SelectedItemsNumber-1 do
    begin
      with SelectedItems^[I] do
      if (Flags and PPIF_GROUP)<>0 then
        TFileSystemObjectList(UserData).Flags:=TFileSystemObjectList(UserData).Flags+[gfDeleted]
      else
        TFileSystemObject(UserData).Flags:=TFileSystemObject(UserData).Flags+[flDeleted];
    end;

//  FFileGroupList.Pack;

end;

var
   PluginStrings: array[0..0] of PChar;

procedure GetPluginInfo(var aInfo: TPluginInfo);
begin
  ZeroMemory(@aInfo, SizeOf(TPluginInfo));
  with aInfo do
  begin
    StructSize := SizeOf(TPluginInfo);
    PluginStrings[0]:=GetMsg(msgPluginMenuString);
    PluginMenuStrings:=@PluginStrings;
    PluginMenuStringsNumber:=1;
    CommandPrefix:=nil;
  end;
end;

End.

