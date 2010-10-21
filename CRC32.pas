unit CRC32;

interface
{$I PRJDefines.inc}
  function Crc32File(const FileName: string): LongWord;

implementation

uses
    Classes, SysUtils;


Const
  Crc32Init = $FFFFFFFF;
  Crc32Polynomial = $EDB88320;

Var
  CRC32Table: array [Byte] of Cardinal;

function  Crc32Next   (Crc32Current: LongWord; const Data; Count: LongWord): LongWord; register;
Asm //EAX - CRC32Current; EDX - Data; ECX - Count
  test  ecx, ecx
  jz    @@EXIT
  PUSH  ESI
  MOV   ESI, EDX  //Data

@@Loop:
    MOV EDX, EAX                       // copy CRC into EDX
    LODSB                              // load next byte into AL
    XOR EDX, EAX                       // put array index into DL
    SHR EAX, 8                         // shift CRC one byte right
    SHL EDX, 2                         // correct EDX (*4 - index in array)
    XOR EAX, DWORD PTR CRC32Table[EDX] // calculate next CRC value
  dec   ECX
  JNZ   @@Loop                         // LOOP @@Loop
  POP   ESI
@@EXIT:
end;//Crc32Next

function  Crc32Done   (Crc32: LongWord): LongWord; register;
Asm
  NOT   EAX
end;//Crc32Done

function  Crc32Initialization: Pointer;
Asm
  push    EDI
  STD
  mov     edi, OFFSET CRC32Table+ ($400-4)  // Last DWORD of the array
  mov     edx, $FF  // array size

@im0:
  mov     eax, edx  // array index
  mov     ecx, 8
@im1:
  shr     eax, 1
  jnc     @Bit0
  xor     eax, Crc32Polynomial  // <магическое> число - тоже что у
@Bit0:
  dec     ECX
  jnz     @im1

  stosd
  dec     edx
  jns     @im0

  CLD
  pop     EDI
  mov     eax, OFFSET CRC32Table
end;//Crc32Initialization

function  Crc32Stream (Source: TStream): LongWord;
var
  BufSize, N: Integer;
  Count: Longint;
  Buffer: PChar;
begin
  Result:=Crc32Init;
  Source.Position:= 0;
  Count:= Source.Size;
{
  if Count > IcsPlusIoPageSize then
    BufSize:= IcsPlusIoPageSize
  else
    BufSize:= Count;
}
  BufSize:=8192;
  GetMem(Buffer, BufSize);
  try
    while Count <> 0 do begin
      if Count > BufSize then N := BufSize else N := Count;
      Source.ReadBuffer(Buffer^, N);
      Result:=Crc32Next(Result,Buffer^,N);
      Dec(Count, N);
    end;
  finally
    Result:=Crc32Done(Result);
    FreeMem(Buffer);
  end;
end;//Crc32Stream

function Crc32File(const FileName: string): LongWord;
var
 F: TFileStream;
begin
 F:=TFileStream.Create(FileName, fmOpenRead);
 try
   Result:=Crc32Stream(F);
 finally
   F.Free;
 end;
end;

Begin
     Crc32Initialization;
End.