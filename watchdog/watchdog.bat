rem Remark out the following line to disable the watchdog:
if exist c:\users\sdi3000\watchdog\console_crash_file.tmp call c:\users\sdi3000\watchdog\restart_sdi3000_obs.bat
echo. |time > c:\users\sdi3000\watchdog\console_crash_file.tmp
exit