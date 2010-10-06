@echo off
windres -i finddup.rc  -o finddup.res
fpc -XX -CX -Mdelphi finddup.dpr

