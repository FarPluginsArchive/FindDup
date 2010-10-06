@echo off
windres -i finddup.rc  -o finddup.res
fpc -Mdelphi finddup.dpr

