;\\ Code formatted by DocGen


;\D\<Check to see if the console `crash' file is present. If it is, it is likely that the>
;\D\<SDI console has stopped running, and this gets logged.>
pro console_crash_routine, log_file  ;\A\<The filename to send/append log output to>

	if file_test(log_file) then begin
		openw, file, log_file, /get_lun, /append
			printf, file
			printf, file, 'Console Crash Suspected - ' + systime() + ' (local time)
		close, file
		free_lun, file
	endif else begin
		openw, file, log_file, /get_lun
			printf, file, '### CONSOLE CRASH LOG ###'
			printf, file
			printf, file, 'Console Crash Suspected - ' + systime() + ' (local time)
		close, file
		free_lun, file
	endelse

end


;\D\<Create the console `crash' file.>
pro console_make_crash_file, crash_file  ;\A\<Filename for the crash file>

	openw, file, crash_file, /get_lun
		printf, file, 'CRASH FILE - THIS SHOULD BE DELETED!!'
	close, file
	free_lun, file

end


;\D\<This gets called by a Windows scheduled script, and checks to see if a crash file is>
;\D\<present (the console should delete this file, so if it is present, the console has likely>
;\D\<crashed), and if so it logs a crash. If not ,it recreates the file.>
pro crash_routines

	crash_file = 'C:\MawsonCode\Crash Folder\console_crash_file'
	log_file   = 'C:\MawsonCode\Crash Folder\console_crash_log.txt'

	there = file_test(crash_file)

	if there eq 1 then console_crash_routine, log_file
	if there eq 0 then console_make_crash_file, crash_file

end
