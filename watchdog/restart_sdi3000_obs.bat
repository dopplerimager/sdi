c:\users\sdi3000\sdi\bin\pstools\pskill -t idlde
sleep 5
c:\users\sdi3000\sdi\bin\devcon\i386\i386\devcon restart usb*
start "Observing..." "C:\Program Files\ITT\IDL64\bin\bin.x86\idlde.exe" @Poker_Auto_SDI_Observations.pro
echo. |time > c:\users\sdi3000\sdi\watchdog\last_watchdog_restart_time.txt
exit
