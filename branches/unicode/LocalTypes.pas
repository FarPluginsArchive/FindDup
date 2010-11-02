{
        Project: FindDupFar http://code.google.com/p/findupfar/
	Author: Alexey Suhinin http://x-alexey.narod.ru
	License: GPL v.2
}

unit LocalTypes;

{$I PRJDefines.inc}

interface
uses
  Windows;

type
{$IFDEF UNICODE}
  TPLocalChar = PWideChar;
  TLocalChar = WideChar;
  TLocalString = UnicodeString;
  TLocalWin32FindData = TWin32FindDataW;
{$ELSE}
  TPLocalChar = PChar;
  TLocalChar = Char;
  TLocalString = AnsiString;
  TLocalWin32FindData = TWin32FindData;
{$ENDIF}
  TLocalCharArr = array of TLocalChar;

implementation
end.
