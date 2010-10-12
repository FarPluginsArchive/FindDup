{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit MainDialogs;

Interface
{$I PRJDefines.inc}
uses
    Windows,
    PluginLng,
    FarApi,
    Plugin;

type
  TMainDialog = class
  private
    class function DlgProc(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer; stdcall; static;
  public
    function Show: Integer;
  end;


Implementation

type
  TMainDialogItemID = (idFrame, idProcessText, idProcessFiles, idProcessDirs, idSeparator1, idAllDisks, idWithoutNetDisks,
                     idCurrentDisk, idCustom, idCurrentPanel, idAnotherPanel, idCustomList, idCustomListBtn, idSeparator2,
		     idOKBtn);
const
  DialogWidth = 54;
  DialogHeight = 15;
  
class function TMainDialog.DlgProc(hDlg: THandle; Msg: integer; Param1: integer; Param2: integer): integer;
begin
  Result:=DefDlgProc(hDlg, Msg, Param1, Param2);
  case Msg of
    DN_BTNCLICK:
    case TMainDialogItemID(Param1) of
      idCustom:
        if SendDlgMessage(hDlg, DM_GETCHECK, Ord(idCustom), 0)=BSTATE_CHECKED then
          begin
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idCurrentPanel), Integer(True));
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idAnotherPanel), Integer(True));
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomList), Integer(True));
            if SendDlgMessage(hDlg, DM_GETCHECK, Ord(idCustomList), 0)=BSTATE_CHECKED then
              SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomListBtn), Integer(True));
          end
        else
          begin
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idCurrentPanel), Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idAnotherPanel), Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomList), Integer(False));
            SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomListBtn), Integer(False));
          end;
      idCustomList:
         if SendDlgMessage(hDlg, DM_GETCHECK, Ord(idCustomList), 0)=BSTATE_CHECKED then   
           SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomListBtn), Integer(True))              
	 else
	   SendDlgMessage(hDlg, DM_ENABLE, Ord(idCustomListBtn), Integer(False));
      end;
    end;
end;

function TMainDialog.Show: Integer;
var
  items: PFarDialogItemArray;
const
  itemsnum=Ord(High(TMainDialogItemID))+1;
  initarray: packed array [0..itemsnum-1] of TInitDialogItem = (
  (ItemType:DI_DOUBLEBOX;   X1: 3; Y1: 1; X2:DialogWidth-4; Y2:DialogHeight-2; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFind))),
  (ItemType:DI_TEXT;        X1: 5; Y1: 2; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindChoise))),
  (ItemType:DI_RADIOBUTTON; X1: 15; Y1: 2; X2: 0; Y2: 0; Focus: 0; Selected: True; Flags:DIF_GROUP; DefaultButton:False; Data: (MsgID: Cardinal(msgFindFiles))),
  (ItemType:DI_RADIOBUTTON; X1: 30; Y1: 2; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindDirs))),
  (ItemType:DI_TEXT;        X1: 0; Y1: 3; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_SEPARATOR; DefaultButton:False; Data: (Message: '')),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 4; X2: 0; Y2: 0; Focus: 0; Selected: True; Flags:DIF_GROUP; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAllDisks))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 5; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAllDisksWithoutNet))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 6; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCurrentDrive))),
  (ItemType:DI_RADIOBUTTON; X1: 5; Y1: 7; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCheck))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 8; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindCurrentPanel))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 9; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindAnotherPanel))),
  (ItemType:DI_CHECKBOX;    X1: 7; Y1: 10; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgFindLists))),
  (ItemType:DI_BUTTON;      X1: 35; Y1: 10; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_DISABLE; DefaultButton:False; Data: (MsgID: Cardinal(msgEDIT))),
  (ItemType:DI_TEXT;        X1: 0; Y1: 11; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:DIF_SEPARATOR; DefaultButton:False; Data: (Message: '')),
  (ItemType:DI_BUTTON;      X1: 7; Y1: 12; X2: 0; Y2: 0; Focus: 0; Selected: False; Flags:0; DefaultButton:True; Data: (MsgID: Cardinal(msgOK)))
  );
begin
  GetMem(items, SizeOf(TFarDialogItem)*itemsnum);
  ZeroMemory(items, SizeOf(TFarDialogItem)*itemsnum);
  InitDialogItems(@initarray, items, itemsnum);
  Result:=DialogEx(-1,-1, DialogWidth, DialogHeight,
                   'Config', items, itemsnum, 0, 0, @TMainDialog.DlgProc, PtrInt(Self));
  FreeMem(items);
end;

End.
