@echo off

set /P name=File name: 
set /P format=Format: 

python.exe c.py %name% -f %format%