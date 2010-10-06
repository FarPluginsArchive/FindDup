{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit MainDialogs;

Interface
uses
    Windows,
    PluginLng,
    FarApi,
    Plugin;

type
  TMainDialog = class
  private
  public
    function Show: Integer;
  end;


Implementation

const
  DialogWidth = 54;
  DialogHeight = 14;

function SettingsDlgProc(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer; stdcall;
const
  BaseID = 4;
begin
  Result:=DefDlgProc(hDlg, Msg, Param1, Param2);
  case Msg of
    DN_BTNCLICK:
      if Param1=BaseID then
        if SendDlgMessage(hDlg, DM_GETCHECK, BaseID, 0)=BSTATE_CHECKED then
          begin
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+1, Integer(True));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+2, Integer(True));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+3, Integer(True));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+4, Integer(True));
          end
        else
          begin
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+1, Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+2, Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+3, Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, BaseID+4, Integer(False));
          end;
  end;
end;

function TMainDialog.Show: Integer;
var
  items: PFarDialogItemArr;
  pMyDlgProc: TFarApiWndProc;
const
//  NulString: PChar = '';
  itemsnum=11;
  initarray: packed array [0..itemsnum-1] of TInitDialogItem = (
  (ItemType:DI_DOUBLEBOX;   X1: 3; Y1: 1; X2:DialogWidth-4; Y2:DialogHeight-2; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFind))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 2; X2: 0; Y2: 0; Focus: 0; Selected: True; Flags:DIF_GROUP; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAllDisks))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 3; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAllDisksWithoutNet))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 4; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCurrentDrive))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 5; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCheck))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 6; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCurrentPanel))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 7; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAnotherPanel))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 8; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindLists))),
  (ItemType:DI_BUTTON;      X1: 35; Y1: 8; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgEDIT))),
  (ItemType:DI_TEXT;        X1: 0; Y1: 9; X2: 0; Y2: 9; Focus: 0; Selected: False; Flags:DIF_SEPARATOR; DefaultButton:False; Data: (Message: '')),
  (ItemType:DI_BUTTON;      X1: 7; Y1: 10; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:True; Data: (MsgID: Cardinal(msgOK)))
  );
begin
  pMyDlgProc:=SettingsDlgProc;
  GetMem(items, SizeOf(TFarDialogItem)*itemsnum);
  ZeroMemory(items, SizeOf(TFarDialogItem)*itemsnum);
  InitDialogItems(@initarray, items, itemsnum);
  Result:=DialogEx(-1,-1, DialogWidth, DialogHeight,
                   'Config', items, itemsnum, 0, 0, pMyDlgProc, 0);
  FreeMem(items);
//  Result:=-1;
end;

End.
