{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit FileSystemObjects;

{$I PRJDefines.inc}

interface

uses
    Classes,
{$IFDEF MD5}
    MD5,
{$ENDIF}
{$IFDEF CRC32}
    CRC32,
{$ENDIF}
    Windows,
    SysUtils;

type
{Возможные флаги объекта TFileSystemObject:
  flDeleted - объект удалён;
  flOpenFalse - попытка открыть файл на чтение (для просчета контрольной суммы)
                неудалась;
  flMD5Calc, flCRC32Calc - установлен,  если соответствующая контрольная сумма
                           уже считалась и хранится в TFileObject
}
  TFileSystemFlags = set of (flDeleted, flOpenFalse, flMD5Calc, flCRC32Calc);

  TCompareFlags = set of (cfSize, cfHash);

  TGroupFlags = set of (gfDeleted, gfSort);

  TFileSystemObject = class;

  TFileSystemObjectList = class(TList)
  private
    FFlags: TGroupFlags;
  protected
    function GetItems(Index: Integer): TFileSystemObject;
    procedure SetItems(Index: Integer; Item: TFileSystemObject);
  public
    constructor Create;
//    destructor Destroy; override;
    function Add(aObject: TFileSystemObject): Integer;
    {Идентичен ли объект уже содержащимся в контейнере? (сравнение с первым элементом в контейнере)}
    function IsDuplicate(aObject: TFileSystemObject): Boolean;
    {Сравнение контейнеров: сначала сортируем файлы по размеру,
     затем циклически сравниваем
     !!!а что если 2 файла с одинаковым размером??? - ошибка!!!}
    function Compare(aObject: TFileSystemObjectList; aFlags: TCompareFlags): Integer;
    procedure Clear; override;
    procedure Delete(Index: Integer);
    {сортирует элементы по размеру}
    procedure Sort;
//    procedure SaveToFile(aFileStream: TFileStream);
    property Items[Index: Integer]: TFileSystemObject read GetItems write SetItems; default;
    property Flags: TGroupFlags read FFlags write FFlags;
  end;

  TFileSystemObject = class
  private
    FRefCount: Byte;         {количество ссылок на объект}
    FFileAttributes: DWORD;
    FCreationTime: TFileTime;
    FLastAccessTime: TFileTime;
    FLastWriteTime: TFileTime;
    FFileSize: INT64;
    FFileName: PChar;
    FFlags: TFileSystemFlags;
    function CompInt(aInt1, aInt2: Int64): Integer;
    procedure SetFileSystemRecord(const aFileSystemRecord: TWin32FindData);
  public
    constructor Create(const aFileSystemRecord: TWin32FindData);
    destructor Destroy; override;
    procedure IncRef;
    procedure DecRef;
    procedure Free;{ virtual;}
    function Compare(aObject: TFileSystemObject; aFlags: TCompareFlags): Integer; virtual; abstract;
    {проверка: существует ли еще файл, и обновление его данных}
{$IFDEF VALIDATE}
    function IsValid: Boolean; virtual; abstract;
{$ENDIF}
    procedure GetFileSystemRecord(var aFileSystemRecord
      {$IFDEF CONTROL_TYPE}: TWin32FindData{$ENDIF});
//    property FileAttributes: DWORD read FFileAttributes;
//    property FileName: PChar read FFileName;
    property Flags: TFileSystemFlags read FFlags write FFlags;
  end;

  TFileObject = class(TFileSystemObject)
  private
{$IFDEF MD5}
    FMD5: TMD5Digest;
    function CalculateMD5: Boolean;
{$ENDIF}
{$IFDEF CRC32}
    FCRC32: LongWord;
    function CalculateCRC32: Boolean;
{$ENDIF}
  public
    function Compare(aObject: TFileSystemObject; aFlags: TCompareFlags): Integer; override;
{$IFDEF VALIDATE}
    function IsValid: Boolean; override;
{$ENDIF}
  end;

  TDirectoryObject = class(TFileSystemObject)
  private
    FDirectorySize: INT64;
    FDirectoryList: TFileSystemObjectList;
  public
    constructor Create(aFileSystemRecord: TWin32FindData);
    destructor Destroy; override;
    function Compare(aObject: TFileSystemObject; aFlags: TCompareFlags): Integer; override;
{$IFDEF VALIDATE}
    function IsValid: Boolean; override;
{$ENDIF}
    procedure AddMember(aObject: TFileSystemObject);
//    procedure Free; override;
  end;

implementation

{реализация TFileSystemObjectList}

constructor TFileSystemObjectList.Create;
begin
     inherited Create;
     FFlags:=[];
end;
{
destructor TFileSystemObjectList.Destroy;
begin
     inherited Destroy;
end;
}
function TFileSystemObjectList.GetItems(Index: Integer): TFileSystemObject;
begin
     Result:=TFileSystemObject(inherited Items[Index]);
end;

procedure TFileSystemObjectList.SetItems(Index: Integer; Item: TFileSystemObject);
begin
     inherited Items[Index]:=Item;
end;

function TFileSystemObjectList.Add(aObject: TFileSystemObject): Integer;
begin
     Result:=inherited Add(pointer(aObject));
     aObject.IncRef;
     Exclude(FFlags, gfSort);
end;

function TFileSystemObjectList.IsDuplicate;
begin
     Result:=False;
     if Count>0 then
       Result:=(TFileSystemObject(Items[0]).Compare(aObject, [cfHash]) = 0);
end;

function TFileSystemObjectList.Compare(aObject: TFileSystemObjectList; aFlags: TCompareFlags): Integer;
var
   I: LongInt;
begin
  if Self<>aObject then
    begin
      Result:=Count-aObject.Count;
      if Result=0 then
      begin
        Sort;
        aObject.Sort;
        I:=0;
        while (I<Count) and (Result=0) do
        begin
          Result:=Items[I].Compare(aObject.Items[I], aFlags);
          Inc(I);
        end;
      end;
  end
  else
    Result:=0
end;

procedure TFileSystemObjectList.Clear;
var
   i: Integer;
begin
     for i:=0 to Count-1 do
     with TFileSystemObject(Items[i]) do
     begin
       DecRef;
       Free;
     end;
     inherited Clear;
end;

procedure TFileSystemObjectList.Delete;
begin
     with TFileSystemObject(Items[Index]) do
     begin
       DecRef;
       Free;
     end;
     inherited Delete(Index);
end;

function CompareFileSystemObject(Item1, Item2: Pointer): Integer;
begin
  Result:=TFileSystemObject(Item1).Compare(Item2, []);
end;

procedure TFileSystemObjectList.Sort;
begin
  if not (gfSort in FFlags) then
  begin
    inherited Sort(CompareFileSystemObject);
    Include(FFlags, gfSort);
  end;
end;
{
procedure TFileSystemObjectList.SaveToFile;
var
   i: Integer;
begin
     for i:=0 to Count-1 do
                           TFileObj(Items[i]).SaveToFile(aFileStream);
end;
}
// реализация TFileSystemObject

constructor TFileSystemObject.Create(const aFileSystemRecord: TWin32FindData);
begin
  inherited Create;
  FRefCount:=0;
  SetFileSystemRecord(aFileSystemRecord);
  FFlags:=[];
end;

destructor TFileSystemObject.Destroy;
begin
  if FFileName<>nil then StrDispose(FFileName);
  inherited Destroy;
end;

procedure TFileSystemObject.IncRef;
begin
  Inc(FRefCount);
end;

procedure TFileSystemObject.DecRef;
begin
  Dec(FRefCount);
end;

procedure TFileSystemObject.Free;
begin
  if FRefCount=0 then
                     inherited Free;
end;

procedure TFileSystemObject.SetFileSystemRecord(const aFileSystemRecord: TWin32FindData);
var
  tmpFileSize: INT64;
begin
  with aFileSystemRecord do
  begin
    FFileAttributes:=dwFileAttributes;
    FCreationTime:=ftCreationTime;
    FLastAccessTime:=ftLastAccessTime;
    FLastWriteTime:=ftLastWriteTime;
    Int64Rec(tmpFileSize).Hi:=nFileSizeHigh;
    Int64Rec(tmpFileSize).Lo:=nFileSizeLow;
    FFileSize:=tmpFileSize;
    if FFileName=nil then FFileName:=StrNew(cFileName);
  end;
end;

procedure TFileSystemObject.GetFileSystemRecord(var aFileSystemRecord{$IFDEF CONTROL_TYPE}: TWin32FindData{$ENDIF});
begin
{$IFDEF CONTROL_TYPE}
  ZeroMemory(@aFileSystemRecord, SizeOf(aFileSystemRecord));
{$ENDIF}
  with TWin32FindData(aFileSystemRecord) do
  begin
    dwFileAttributes:=FFileAttributes;
    ftCreationTime:=FCreationTime;
    ftLastAccessTime:=FLastAccessTime;
    ftLastWriteTime:=FLastWriteTime;
    nFileSizeHigh:=Int64Rec(FFileSize).Hi;
    nFileSizeLow:=Int64Rec(FFileSize).Lo;
    StrCopy(cFileName, FFileName);
  end;
end;

function TFileSystemObject.CompInt(aInt1, aInt2: Int64): Integer;
begin
  if aInt1=aInt2 then
    Result:=0
  else
    if aInt1>aInt2 then
      Result:=1
    else
      Result:=-1;
end;

// реализация TFileObject

{$IFDEF MD5}
function TFileObject.CalculateMD5;
begin
  if flOpenFalse in FFlags then
    Result:=False
  else
    try
      if not (flMD5Calc in FFlags) then
      begin
        FMD5:=MD5File(StrPas(FFileName));
        Include(FFlags, flMD5Calc);
      end;
      Result:=True;
    except
      Include(FFlags, flOpenFalse);
      Result:=False;
    end;
end;
{$ENDIF}

{$IFDEF CRC32}
function TFileObject.CalculateCRC32;
begin
  if flOpenFalse in FFlags then
    Result:=False
  else
    try
      if not (flCRC32Calc in FFlags) then
      begin
        FCRC32:=CRC32File(StrPas(@FFileName));
        Include(FFlags, flCRC32Calc);
      end;
      Result:=True;
    except
      Include(FFlags, flOpenFalse);
      Result:=False;
    end;
end;
{$ENDIF}

{$IFDEF CMPDIRECT}
function FileCompare(aFileName1, aFileName2: string): Integer;

  function Min(X, Y: LongInt): LongInt;
  begin
    Result := X;
    if X > Y then Result := Y;
  end;

const
  BufSize = 32768;
var
  FileBuffer1, FileBuffer2: array[1..BufSize] of Byte;
  File1, File2: TFileStream;
  RestBufCount, RestFileCount: LongInt;
begin
  Result:=0;
  try
    File1:=TFileStream.Create(aFileName1, fmOpenRead or fmShareDenyNone);
    try
      try
        File2:=TFileStream.Create(aFileName2, fmOpenRead or fmShareDenyNone);
        try
          RestFileCount:=Min(File1.Size, File2.Size);
          while (Result=0) and (RestFileCount>0) do
          begin
            RestBufCount:=Min(BufSize, RestFileCount);
            File1.ReadBuffer(FileBuffer1, RestBufCount);
            File2.ReadBuffer(FileBuffer2, RestBufCount);
            while (Result=0) and (RestBufCount>0) do
            begin
              Result:=FileBuffer1[RestBufCount]-FileBuffer2[RestBufCount];
              Dec(RestBufCount);
              Dec(RestFileCount);
            end;
          end;
        finally
          File2.Free;
        end;
       except
         Result:=1;
       end;
    finally
      File1.Free;
    end;
  except
    Result:=1;
  end;
end;
{$ENDIF}

function TFileObject.Compare(aObject: TFileSystemObject; aFlags: TCompareFlags): Integer;
{$IFDEF MD5}
var
   I: LongInt;
{$ENDIF}
begin
  if Self<>aObject then
    if aObject is TFileObject then
      begin
        Result:=CompInt(FFileSize,
                        aObject.FFileSize);
        if (Result=0) and (cfHash in aFlags) then
        begin
{$IFDEF MD5}
          I:=0;
          if CalculateMD5 and (aObject as TFileObject).CalculateMD5 then
            while (I<16) and (Result=0) do
            begin
                 Result:=FMD5.V[I]-(aObject as TFileObject).FMD5.V[I];
                 Inc(I);
            end
          else
            Result:=-1;
{$ENDIF}
{$IFDEF CRC32}
          if CalculateCRC32 and (aObject as TFileObject).CalculateCRC32 then
            Result:=FCRC32-(aObject as TFileObject).FCRC32
          else
            Result:=-1;
{$ENDIF}
{$IFDEF CMPDIRECT}
          Result:=FileCompare(StrPas(FFileName), StrPas((aObject as TFileObject).FFileName));
{$ENDIF}
        end;
      end
    else
      Result:=-1
  else
    Result:=0;
end;

{
function TFileObject.IsValid: Boolean;
var
   FindData: TWin32FindData;
   hFindFile: THandle;
begin
  Result:=False;
  hFindFile:=FindFirstFile(FFileName, FindData);
  if hFindFile<>INVALID_HANDLE_VALUE then
    begin
      SetFileSystemRecord(FindData);
      Windows.FindClose(hFindFile);
      Result:=True;
    end
  else
    Include(FFlags, flDeleted);
end;
}
{$IFDEF VALIDATE}
// конечно такая проверка не корректна, ведь файл могли не только изменить,
// но и отредактировать
function TFileObject.IsValid: Boolean;
var
   AttributeData: TWin32FileAttributeData;
begin
  Result:=False;
  if GetFileAttributesEx(FFileName, GetFileExInfoStandard, @AttributeData) then
    Result:=True
  else
    Include(FFlags, flDeleted);
end;
{$ENDIF}


// реализация TDirectoryObject

constructor TDirectoryObject.Create(aFileSystemRecord: TWin32FindData);
begin
  inherited Create(aFileSystemRecord);
  FFileSize:=0;
//  FLinksCount:=0;
  FDirectoryList:=TFileSystemObjectList.Create;
end;

destructor TDirectoryObject.Destroy;
begin
  FDirectoryList.Free;
  inherited Destroy;
end;
{
procedure TDirectoryObject.Free;
begin
  if FLinksCount=0 then
    begin
      inherited Free;
    end
  else
    Dec(FLinksCount);
end;
}
function TDirectoryObject.Compare(aObject: TFileSystemObject; aFlags: TCompareFlags): Integer;
begin
  if Self<>aObject then
    if aObject is TDirectoryObject then
      begin
        Result:=CompInt(FDirectorySize, (aObject as TDirectoryObject).FDirectorySize);
        if (Result=0) then
        begin
          Result:=FDirectoryList.Compare(
                  (aObject as TDirectoryObject).FDirectoryList, aFlags);
        end;
      end
    else
      Result:=1
  else
    Result:=0;
end;

{$IFDEF VALIDATE}
function TDirectoryObject.IsValid: Boolean;
begin
  Result:=False;
  FFileAttributes:=GetFileAttributes(FFileName);
  if FFileAttributes<>INVALID_HANDLE_VALUE then
    Result:=True
  else
    Include(FFlags, flDeleted);
end;
{$ENDIF}

procedure TDirectoryObject.AddMember(aObject: TFileSystemObject);
begin
  if aObject<>nil then
  begin
{
    if aObject is TDirectoryObject then
      Inc((aObject as TDirectoryObject).FLinksCount);
}
    FDirectoryList.Add(aObject);
    Inc(FDirectorySize, aObject.FFileSize);
  end;
end;


end.
