### This Script contains Unix-Line-Endings
### You can edit this file with a unix-editor
###
### Diese Datei enthält Unix-Zeilentrennen
### Sie kann mit einem Unix-Editor editiert werden
###

rem @echo off
rem login-script user

rem Synchronizing the clock
net time \\$smb_netbios_name /set /yes
rem > nul

rem Connecting the home-share.
net use h: \\$smb_netbios_name\homes /yes 
rem > nul

rem Connecting the programs-share.
net use p: \\$smb_netbios_name\pgm /yes
rem > nul
