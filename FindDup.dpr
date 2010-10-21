{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}


library FindDup;
{.$O-}
{$I PRJDefines.inc}
{$APPTYPE CONSOLE}

uses
{$IFDEF DEBUG}
  DebugLog,
{$ENDIF}
  Windows,
  Plugin,
  Main,
  FarApi,
  SysUtils;

{$R *.res}

var
  StartDir: array[1..MAX_PATH] of Char;

function OpenPlugin(OpenFrom: integer{TOpenModes}; Item: integer): THandle; StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "OpenPlugin"', 2);
{$ENDIF}
     try
       Result:=THandle(TFarPlugin.Create);
       GetCurrentDirectory(MAX_PATH, @StartDir);
     except
       Result:=INVALID_HANDLE_VALUE;
     end;
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "OpenPlugin"', -2);
{$ENDIF}
end;

procedure ClosePlugin(Plugin: THandle); StdCall; Export;
begin
//  try
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "ClosePlugin"', 2);
{$ENDIF}
    try
      TFarPlugin(Plugin).Free;
    finally
      Control(INVALID_HANDLE_VALUE, FCTL_SETPANELDIR, @StartDir);
    end;
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "ClosePlugin"', -2);
{$ENDIF}
//  except
//  end;
end;

procedure GetOpenPluginInfo(Plugin: THandle; var aInfo: TOpenPluginInfo); StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "GetOpenPluginInfo"', 2);
{$ENDIF}
  TFarPlugin(Plugin).GetOpenPluginInfo(aInfo);
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "GetOpenPluginInfo"', -2);
{$ENDIF}
end;

function GetFindData(Plugin: THandle; var aPanelItems: PPluginPanelItemArray;
                     var aItemsNumber: integer; opMode: integer): integer; StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "GetFindData"', 2);
{$ENDIF}
  Result:=TFarPlugin(Plugin).GetFindData(aPanelItems, aItemsNumber, opMode);
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "GetFindData"', -2);
{$ENDIF}
end;

procedure FreeFindData(Plugin: THandle; aPanelItems: PPluginPanelItemArray;
                       aItemsNumber: integer); StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "FreeFindData"', 2);
{$ENDIF}
  TFarPlugin(Plugin).FreeFindData(aPanelItems, aItemsNumber);
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "FreeFindData"', -2);
{$ENDIF}
end;
{
function DeleteFiles(Plugin: THandle; PanelItem: PPluginPanelItemArr;
                     ItemsNumber, opMode: integer): integer; StdCall; Export;
begin
  result:=Integer(False);
end;
}
function ProcessEvent(hPlugin: THandle; Event: Integer; Param: pointer): integer; StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "ProcessEvent"', 2);
{$ENDIF}
//  if flPlugOpen then
    Result:=TFarPlugin(hPlugin).ProcessEvent(Event, Param);
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "ProcessEvent"', -2);
{$ENDIF}
end;

function ProcessKey(hPlugin: THandle; Key: Integer; ControlState: UINT): integer; StdCall; Export;
begin
{$IFDEF DEBUG}
     AddDebugStringToLog('Enter to "ProcessKey"', 2);
{$ENDIF}
  result:= TFarPlugin(hPlugin).ProcessKey(Key, ControlState);
{$IFDEF DEBUG}
     AddDebugStringToLog('Exit to "ProcessKey"', -2);
{$ENDIF}
end;

exports
  SetStartupInfo,
  GetPluginInfo,
  OpenPlugin,
  ClosePlugin,
  GetOpenPluginInfo,
  GetFindData,
  FreeFindData,
  ProcessEvent,
  ProcessKey;
//  DeleteFiles;

{
  flPlugOpen:=False;
}
Begin
End.
