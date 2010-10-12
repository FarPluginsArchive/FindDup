{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit MyInt64;
{$I PRJDefines.inc}
interface
type
  INT64 = Comp;
//  INT64 = array [0..7] of Byte;
  Int64Rec = packed record
    Lo, Hi: Cardinal;
  end;
{
  Int64Rec = packed record
    case Integer of
      0: (Lo, Hi: Cardinal);
      1: (Cardinals: array [0..1] of Cardinal);
      2: (Words: array [0..3] of Word);
      3: (Bytes: array [0..7] of Byte);
      4: (I: INT64);
  end;
}
procedure IncInt64(Var Op1: Int64; const Op2: Int64);

implementation

procedure IncInt64(Var Op1: Int64; const Op2: Int64);
  asm
    push eax
    push ecx
    mov ecx,Op1
    mov eax,Int64Rec(Op2).Lo
    add Int64Rec([ecx]).Lo, eax
    mov eax,Int64Rec(Op2).Hi
    adc Int64Rec([ecx]).Hi, eax
    pop ecx
    pop eax
  end;

End.
