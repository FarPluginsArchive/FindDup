{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit DebugLog;


interface
  procedure AddDebugStringToLog(aSt: String; aSpace: Integer);

implementation

var
  Shift: Integer = 0;
  S: String = '                                                                        ';

procedure AddDebugStringToLog(aSt: String; aSpace: Integer);
var
   F: Text;
begin
   Assign(F, 'D:\FindDup.log');
{$I-}
   Append(F);
{$I+}

   if aSpace<0 then Inc(Shift, aSpace);
   if IOResult<>0 then Rewrite(F);
   Writeln(F, Copy(S, 1, Shift)+aSt);
   Close(F);
   if aSpace>0 then Inc(Shift, aSpace);
end;

end.