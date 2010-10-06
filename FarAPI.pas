unit FarAPI;

Interface
{$I PRJDefines.inc}

uses
    Plugin,
    PluginLng,
    SysUtils,
    Windows;

type

  TInitDialogItem = packed record
    ItemType: integer;
    X1, Y1, X2, Y2: integer;
    Focus: integer;
    Selected: Bool;
{
    Param: record case integer of
      0: (Selected: BOOL);
      1: (History: PChar);
      2: (Mask: PChar);
      3: (ListItems: PFarList);
      4: (ListPos: integer);
      5: (VBuf: PCharInfo);
    end;
}
    Flags: DWORD;
    DefaultButton: BOOL;
    Data: record case Integer of
      0: (MsgID: DWORD);
      1: (Message: PChar);
    end;

  end;
  TInitDialogItemArr = packed array [0..Pred(MaxInt div SizeOf(TInitDialogItem))] of TInitDialogItem;
  PInitDialogItemArr = ^TInitDialogItemArr;

function GetPluginPath: String;
procedure SetStartupInfo(var aInfo: TPluginStartupInfo); stdcall;
function GetMsg(aMsgId: TMessageStrings): PChar;
function Message(Flags: DWORD; HelpTopic: PChar;
                 AItems: array of const; ButtonsNumber: Integer): Integer;
function SaveScreen(X1, Y1, X2, Y2: integer): THandle;
procedure RestoreScreen(hScreen: THandle);
function CmpName(const Pattern: PChar; const FileName: PChar;
                 SkipPath: BOOL): Bool;
function Control(hPlugin: THandle; Command: integer; Param: pointer): integer;
procedure InitDialogItems(Init: PInitDialogItemArr; Item: PFarDialogItemArr;
                          ItemsNumber: integer);
function DialogEx(X1, Y1: integer; X2, Y2: integer; HelpTopic: PChar;
                  Items: PFarDialogItemArr; ItemsNumber: integer;
                  Reserved: DWORD; Flags: DWORD; DlgProc: TFarApiWndProc;
                  Param: integer): integer;
function DefDlgProc(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer;
function SendDlgMessage(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer;
function CheckForEsc: Boolean;

function ConvertNameToReal(const Src: PChar; Dest: PChar; DestSize: Integer): Integer;

{
function GetDirList(const aDir: PChar;
                    var aPanelItems: PPluginPanelItemArr;
                    var aItemsNumber: integer): integer;
procedure FreeDirList(const aPanelItems: PPluginPanelItemArr);
}
Implementation

var
  PluginStartupInfo: TPluginStartupInfo;
  FSF: TFarStandardFunctions;
  hConInp: THandle;

function GetPluginPath: String;
{
var
   F: TextFile;
}
begin
     Result:=ExtractFileDir(StrPas(PChar(@PluginStartupInfo.ModuleName)))+'\';
{
     AssignFile(F, 'c:\debug.txt');
     Rewrite(F);
     Writeln(F, Result);
     CloseFile(F);
}
end;

procedure SetStartupInfo(var aInfo: TPluginStartupInfo); {stdcall;}
var
   Size: Integer;
begin
     Size:=aInfo.StructSize;
     if Size>SizeOf(TPluginStartupInfo) then Size:=SizeOf(TPluginStartupInfo);
     Move(aInfo, PluginStartupInfo, Size);
     PluginStartupInfo.StructSize:=Size;
     Size:=aInfo.FSF^.StructSize;
     if Size>SizeOf(TFarStandardFunctions) then Size:=SizeOf(TFarStandardFunctions);
     Move(aInfo.FSF^, FSF, Size);
     FSF.StructSize:=Size;
     PluginStartupInfo.FSF:=@FSF;
end;

function GetMsg(aMsgId: TMessageStrings): PChar;
begin
  with PluginStartupInfo do
    Result:=GetMsg(ModuleNumber,integer(aMsgId));
end;

function Message(Flags: DWORD; HelpTopic: PChar;
                 AItems: array of const; ButtonsNumber: Integer): Integer;
var
  Items: PPCharArr;
  ItemsNumber: Integer;
  I: Integer;
begin
  ItemsNumber := High(AItems)+1;
  GetMem(Items, SizeOf(PChar)*ItemsNumber);

  for I := 0 to High(AItems) do
    with AItems[I] do
      case VType of
        vtInteger: Items^[I] := GetMsg(TMessageStrings(VInteger));
        vtPChar: Items^[I] := VPChar;
        vtAnsiString: Items^[I] := VAnsiString;
        else{nil} Items^[I] := ' ';
      end;


  with PluginStartupInfo do
    Result := Message(ModuleNumber,
      Flags,
      HelpTopic,
      Items,
      ItemsNumber,
      ButtonsNumber);

  FreeMem(Items);
end;

function SaveScreen(X1, Y1, X2, Y2: integer): THandle;
begin
  Result:=PluginStartupInfo.SaveScreen(X1, Y1, X2, Y2);
end;

procedure RestoreScreen(hScreen: THandle);
begin
  PluginStartupInfo.RestoreScreen(hScreen);
end;

function CmpName(const Pattern: PChar; const FileName: PChar;
                 SkipPath: BOOL): Bool;
begin
  Result:=Bool(PluginStartupInfo.CmpName(Pattern, FileName, SkipPath));
end;

function Control(hPlugin: THandle; Command: integer; Param: pointer): integer;
begin
     Result:=PluginStartupInfo.Control(hPlugin, Command, Param);
end;

procedure InitDialogItems(Init: PInitDialogItemArr; Item: PFarDialogItemArr;
                          ItemsNumber: integer);
var
  i: integer;
begin
  for i:=0 to ItemsNumber-1 do
  begin
    Item^[I].ItemType:=Init^[I].ItemType;
    Item^[I].X1:=Init^[I].X1;
    Item^[I].Y1:=Init^[I].Y1;
    Item^[I].X2:=Init^[I].X2;
    Item^[I].Y2:=Init^[I].Y2;
    Item^[I].Focus:=Init^[I].Focus;
    Item^[I].Param.Selected:=Init^[I].Selected;
    Item^[I].Flags:=Init^[I].Flags;
    Item^[I].DefaultButton:=Init^[I].DefaultButton;
    if Init^[I].Data.MsgID<2000 then
      StrCopy(Item^[I].Data.Data, GetMsg(TMessageStrings(Init^[I].Data.MsgID)))
    else
      StrCopy(Item^[I].Data.Data, Init^[I].Data.Message);
  end;
end;

function DialogEx(X1, Y1: integer; X2, Y2: integer; HelpTopic: PChar;
                  Items: PFarDialogItemArr; ItemsNumber: integer;
                  Reserved: DWORD; Flags: DWORD; DlgProc: TFarApiWndProc;
                  Param: integer): integer;
begin
  Result:=PluginStartupInfo.DialogEx(PluginStartupInfo.ModuleNumber,
                                     X1, Y1, X2, Y2, HelpTopic,
                                     Items, ItemsNumber, Reserved,
                                     Flags, DlgProc, Param);
end;

function DefDlgProc(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer;
begin
  Result:=PluginStartupInfo.DefDlgProc(hDlg, Msg, Param1, Param2);
end;

function SendDlgMessage(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer;
begin
  Result:=PluginStartupInfo.SendDlgMessage(hDlg, Msg, Param1, Param2);
end;

function CheckForEsc: Boolean;
var
//   hConInp: THandle;
   Rec: TInputRecord;
   ReadCount: DWord;
begin
  Result:=False;
//  hConInp:=GetStdHandle(STD_INPUT_HANDLE);
  repeat
    PeekConsoleInput(hConInp, rec, 1, ReadCount);
    if ReadCount>0 then
    begin
      ReadConsoleInput(hConInp, rec, 1, ReadCount);
      if (Rec.EventType=KEY_EVENT) and
{$IFNDEF OLD_PAS}
         (Rec.Event.KeyEvent.wVirtualKeyCode=VK_ESCAPE) and
         (Rec.Event.KeyEvent.bKeyDown) then
{$ELSE}
         (Rec.KeyEvent.wVirtualKeyCode=VK_ESCAPE) and
         (Rec.KeyEvent.bKeyDown) then
{$ENDIF}
      Result:=True;
    end
  until ReadCount=0;
end;

function ConvertNameToReal(const Src: PChar; Dest: PChar; DestSize: Integer): Integer;
begin
  Result:=PluginStartupInfo.FSF^.ConvertNameToReal(Src, Dest, DestSize);
end;

(*
bool CheckForEsc(void)
{
 bool EC=false;
 INPUT_RECORD rec;
 static HANDLE hConInp=GetStdHandle(STD_INPUT_HANDLE);
 DWORD ReadCount;
 while (1)
 {
  PeekConsoleInput(hConInp,&rec,1,&ReadCount);
  if (ReadCount==0) break;
  ReadConsoleInput(hConInp,&rec,1,&ReadCount);
  if (rec.EventType==KEY_EVENT)
     if (rec.Event.KeyEvent.wVirtualKeyCode==VK_ESCAPE &&
         rec.Event.KeyEvent.bKeyDown) EC=true;
 }
 return(EC);
}
*)
{
function GetDirList(const aDir: PChar;
                    var aPanelItems: PPluginPanelItemArr;
                    var aItemsNumber: integer): integer;
begin
     Result:=PluginStartupInfo.GetDirList(aDir, aPanelItems, aItemsNumber);
end;

procedure FreeDirList(const aPanelItems: PPluginPanelItemArr);
begin
     PluginStartupInfo.FreeDirList(aPanelItems);
end;
}
initialization
  hConInp:=GetStdHandle(STD_INPUT_HANDLE);
//finalization
//  CloseHandle(hConInp);
End.
