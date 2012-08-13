;\\ Code formatted by DocGen


;\D\<Restart the MOXA USB hub, using pstools (TODO: is this used? Paths are hard coded...)>
pro restart_moxa

	print, 'Disabling the Moxa device...'
	spawn, 'c:\devcon\i386\devcon disable "USB\Vid_110a&Pid_1040&Rev_0128"', res, err, /noshell
	print, 'Result:', res
	print, 'Errors:', err
	print, 'Waiting 5 seconds...'
	wait, 5
	print, 'Enabling the Moxa device...'
	spawn, 'c:\devcon\i386\devcon enable "USB\Vid_110a&Pid_1040&Rev_0128"', res, err, /noshell
	print, 'Result:', res
	print, 'Errors:', err

end
