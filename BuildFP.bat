@echo off
windres -i finddup.rc  -o finddup.res
fpc -Mobjfpc finddup.dpr

