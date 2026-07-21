@echo off
rem Definitive-run launcher: runs 0_master.do in Stata batch mode (/e, no
rem completion popup), then drops an rc sentinel so pollers know Stata exited.
cd /d C:\git\ckt\RP7\scripts
start /wait "" "C:\Program Files\StataNow19\StataMP-64.exe" /e do 0_master.do
echo stata-exited > C:\git\ckt\RP7\tests\definitive_run_rc.txt
