{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit FileUtils;

{$I PRJDefines.inc}

interface


uses
    Classes,
    FileSystemObjects,
//    Windows,
    SysUtils;

type

  TFileGroupListFlags = set of (flShowUnGroupped);
  TFileGroupList = class(TList)
  private
    FFlags: TFileGroupListFlags;
    FUnGrpFileList: TFileSystemObjectList;
//    FTotalFiles: Integer;
    FGroupedFilesCount: Integer;
//    FGroupsCount: Integer;
  protected
    property Count;
    function GetItems(Index: Integer): TFileSystemObjectList;
//    procedure SetItems(Index: Integer; Item: TFileSystemObjectList);
    function GetGroupsCount: Integer;
    function GetGroupedFilesCount: Integer;
  public
{
    property GroupsCount: Integer read FGroupsCount;
    property GroupedFilesCount: Integer read FGroupedFilesCount;
}
    property GroupsCount: Integer read GetGroupsCount;
    property GroupedFilesCount: Integer read GetGroupedFilesCount;
    property Items[Index: Integer]: TFileSystemObjectList read GetItems{ write SetItems}; {$IFNDEF VPASCAL} default; {$ENDIF}
    constructor Create;
    destructor Destroy; override;
    function Add(aFileObj: TFileSystemObject): Integer;
    procedure Clear; {$IFNDEF OLD_PAS} override; {$ENDIF}
    procedure DeleteFileByIndex(I, J: Integer);
    procedure Delete(Index: Integer);
{$IFDEF VALIDATE}
    procedure Validate;
{$ENDIF}
    procedure Pack;
    procedure ChangeMode;
{$IFDEF SORT_PANEL}
    procedure Sort;
{$ENDIF}
  end;

{$IFDEF VER100}
  procedure FreeAndNil(var Obj);
{$ENDIF}

implementation

{$IFDEF VER100}
procedure FreeAndNil(var Obj);
var
  Temp: TObject;
begin
  Temp := TObject(Obj);
  Pointer(Obj) := nil;
  Temp.Free;
end;
{$ENDIF}

{реализация TFileGroupList}

function TFileGroupList.GetItems(Index: Integer): TFileSystemObjectList;
begin
  if flShowUnGroupped in FFlags then
    Result:=FUnGrpFileList
  else
    Result:=TFileSystemObjectList(inherited Items[Index]);
end;
{
procedure TFileGroupList.SetItems(Index: Integer; Item: TFileSystemObjectList);
begin
  inherited Items[Index]:=Item;
end;
}
function TFileGroupList.GetGroupsCount: Integer;
begin
  if flShowUnGroupped in FFlags then
    Result:=1
  else
    Result:=Count;
end;

function TFileGroupList.GetGroupedFilesCount: Integer;
begin
  if flShowUnGroupped in FFlags then
    Result:=FUnGrpFileList.Count
  else
    Result:=FGroupedFilesCount;
end;

constructor TFileGroupList.Create;
begin
  inherited Create;
  FUnGrpFileList:=TFileSystemObjectList.Create;
  FGroupedFilesCount:=0;
  FFlags:=[];
end;

destructor TFileGroupList.Destroy;
begin
     FreeAndNil(FUnGrpFileList);
{$IFDEF OLD_PAS}
     Clear;
{$ELSE}
     inherited Destroy;
{$ENDIF}
end;

function TFileGroupList.Add;
var
  tmpFileGroup: TFileSystemObjectList;
  I: Integer;
begin
{если количество групп объектов больше нуля, то пытаемся найти группу содержащую
 дубликаты текущего объекта.}
     I:=0;
     if Count>0 then
     begin
       while (I<Count) and
             (not TFileSystemObjectList(Items[I]).IsDuplicate(aFileObj)) do Inc(I);
     end;
{если количество групп объектов равно нулю или индекс найденной группы больше
 общего количества групп, то текущий объект не имеет дубликатов среди списка
 дубликатов, ищем его дубликаты в списке объектов не имеющих дубликатов}
     if (Count=0) or (I=Count) then
       begin
         I:=0;
         if FUnGrpFileList.Count>0 then
         begin
           while (I<FUnGrpFileList.Count) and
                 (FUnGrpFileList.Items[I].Compare(aFileObj, [cfHash])<>0) do Inc(I);
         end;
         if (FUnGrpFileList.Count=0) or (I=FUnGrpFileList.Count) then
{если число объектов в списке равно нулю или индекс найденного объекта больше
 общего числа объектов, то текущий объект не имеет дубликатов. Добавляем его в
 список не дубликатов}
           Result:=FUnGrpFileList.Add(aFileObj)
         else
{дубликат текущего объекта найден в списке объектов не имеющих дубликатов}
           begin
{создаем новую группу в списке дубликатов}
             tmpFileGroup:=TFileSystemObjectList.Create;
             inherited Add(pointer(tmpFileGroup));
{заносим в созданную группу найденный и текущий объект}
             tmpFileGroup.Add(FUnGrpFileList.Items[I]);
             Result:=tmpFileGroup.Add(aFileObj);
{удаляем найденный объект из списка не дубликатов}
             FUnGrpFileList.Delete(I);
             Inc(FGroupedFilesCount, 2);
           end;
       end
     else
       begin
         Result:=TFileSystemObjectList(Items[I]).Add(aFileObj);
         Inc(FGroupedFilesCount);
       end;
end;

procedure TFileGroupList.Clear;
var
   i: Integer;
begin
     if Assigned(FUnGrpFileList) then FUnGrpFileList.Clear;
     for i:=0 to Count-1 do
                           TFileSystemObjectList(inherited Items[i]).Free;
//     FTotalFiles:=0;
     FGroupedFilesCount:=0;
//     FGroupsCount:=0;
     inherited Clear;
end;

procedure TFileGroupList.DeleteFileByIndex(I, J: Integer);
begin
  with Items[I] do
  begin
    Delete(J);
    if not (flShowUnGroupped in FFlags) then // !!!похоже это лишнее, ибо , если показываем без групп, то сюда мы и не попадём.
      Dec(FGroupedFilesCount);
  end;
end;

procedure TFileGroupList.Delete;
begin
  if not (flShowUnGroupped in FFlags) then
  begin
    Dec(FGroupedFilesCount, Items[Index].Count);
    TFileSystemObjectList(Items[Index]).Free;
    inherited Delete(Index);
  end;
end;

{$IFDEF VALIDATE}
procedure TFileGroupList.Validate;
var
  I, J: LongInt;
begin
  for I:=0 to GroupsCount-1 do
    if Items[I].Count>1 then
      for J:=0 to Items[I].Count-1 do
        Items[I].Items[J].IsValid;
    Pack;
end;
{$ENDIF}


procedure TFileGroupList.Pack;
var
  I, J, StepI: LongInt;
begin
  I:=0;
  while I<GroupsCount do
  if (not (flShowUnGroupped in FFlags)) and
     (
{$IFDEF AUTO_GROUP_REMOVE}
      (Items[I].Count<2) or // скрываем группу, если в ней осталось менее двух элементов
{$ELSE}
      (Items[I].Count<1) or // скрываем пустую группу
{$ENDIF}
      (gfDeleted in Items[I].Flags)) then
    Delete(I)
  else
    begin
      J:=0;
      StepI:=1;
      while J<Items[I].Count do
      if flDeleted in Items[I].Items[J].Flags then
        begin
          StepI:=0;
          DeleteFileByIndex(I, J);
        end
      else
        Inc(J);
      Inc(I, StepI);
    end;
//  Inherited Pack;
end;

procedure TFileGroupList.ChangeMode;
begin
  if flShowUnGroupped in FFlags then
    Exclude(FFlags, flShowUnGroupped)
  else
    Include(FFlags, flShowUnGroupped);
end;

{$IFDEF SORT_PANEL}
function Compare(Item1, Item2: Pointer): Integer;
begin
  Result:=TFileSystemObject(TFileSystemObjectList(Item1).Items[0]).Compare(TFileSystemObject(TFileSystemObjectList(Item2).Items[0]), []);
end;

procedure TFileGroupList.Sort;
begin
  inherited Sort(Compare);
end;
{$ENDIF}
end.
