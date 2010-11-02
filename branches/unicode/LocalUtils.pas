unit LocalUtils;
{$I PRJDefines.inc}

interface
uses
  LocalTypes;

function LocalStrLen(P: TPLocalChar): SizeInt; inline;
function LocalStrCopy(Dest, Source: TPLocalChar): TPLocalChar; inline;
function LocalStrCopyCat(StrArr: array of TPLocalChar): TPLocalChar;
procedure LocalStrDispose(Str: TPLocalChar); inline;


implementation

function LocalStrLen(P: TPLocalChar): SizeInt; inline;
begin
  Result:=0;
  if Assigned(P) then while TLocalCharArr(P)[Result]<>#0 do Inc(Result);
end;

function LocalStrCopy(Dest, Source: TPLocalChar): TPLocalChar; inline;
begin
  Result:=Dest;
  if Assigned(Dest) and Assigned(Source) then
    Move(Source^, Dest^, (LocalStrLen(Source)+1)*SizeOf(TLocalChar));
end;

{
function LocalStrCopy(Dest, Source: TPLocalChar): TPLocalChar; inline;
var
  i: SizeInt;
begin
  i:=0;
  Result:=nil;
  if Assigned(Dest) and Assigned(Source) then
  begin
    while TLocalCharArr(Source)[i]<>#0 do
    begin
      TLocalCharArr(Dest)[i]:=TLocalCharArr(Source)[i];
      Inc(i);
    end;
    TLocalCharArr(Dest)[i]:=#0;
    Result:=Dest;
  end;
end;
}
function LocalStrCopyCat(StrArr: array of TPLocalChar): TPLocalChar;
var
  I, J, Len: SizeInt;
begin
  Len:=0;
  Result:=nil;
  for I:=0 to High(StrArr) do Inc(Len, LocalStrLen(StrArr[I]));
  if Len>0 then
  begin
    GetMem(Result, (Len+1)*SizeOf(TLocalChar));
    J:=0;
    if Result<>nil then
    begin
      for I:=0 to High(StrArr) do
        if Assigned(StrArr[I]) then
        begin
          Len:=LocalStrLen(StrArr[I]);
          Move(StrArr[I]^, TLocalCharArr(Result)[J], Len*SizeOf(TLocalChar));
          Inc(J, Len);
        end;
      TLocalCharArr(Result)[J]:=#0;
    end;
  end;
end;

procedure LocalStrDispose(Str: TPLocalChar); inline;
begin
  FreeMem(Str);
end;

end.
