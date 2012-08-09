
;\\ This is called if the crash_test_batch thinks the console has crashed

pro console_crash_routine, log_file

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


;\\ This makes the crash file which should be deleted by the console

pro console_make_crash_file, crash_file

	openw, file, crash_file, /get_lun
		printf, file, 'CRASH FILE - THIS SHOULD BE DELETED!!'
	close, file
	free_lun, file

end


;\\ This tests for crash

pro crash_routines

	crash_file = 'C:\MawsonCode\Crash Folder\console_crash_file'
	log_file   = 'C:\MawsonCode\Crash Folder\console_crash_log.txt'

	there = file_test(crash_file)

	if there eq 1 then console_crash_routine, log_file

	if there eq 0 then console_make_crash_file, crash_file

end
