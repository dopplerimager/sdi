
pro data_transfer, data_dir = data_dir, $
				   sent_dir = sent_dir, $
				   ftp_command = ftp_command, $
				   site = site, $
				   dry_run = dry_run


	if not keyword_set(data_dir) then begin
		print, 'Need keyword data_dir'
		return
	endif

	if not keyword_set(sent_dir) then begin
		print, 'Need keyword sent_dir'
		return
	endif

	if not keyword_set(ftp_command) then begin
		print, 'Need keyword ftp_command'
		return
	endif

	if not keyword_set(site) then begin
		print, 'Need keyword site'
		return
	endif


	openw, log_handle, 'c:\users\sdi3000\log\data_transfer_log.txt', /get

	;\\ Get the list of files awaiting transfer or move
		files = file_search(data_dir + '\*.nc', count = nfiles)

		printf, log_handle, 'Files in ' + data_dir
		for i = 0, nfiles - 1 do printf, log_handle, files[i]

	;\\ Get the processed list from the server and read in file names
		ftp_script = 'c:\SDI_ftp_script.ftp'
		openw, spunt, ftp_script, /get_lun
		printf, spunt, 'option echo on'
		printf, spunt, 'option batch abort'
		printf, spunt, 'option confirm off'
		printf, spunt, 'open ' + ftp_command
		printf, spunt, 'cd instrument_incomming'
		printf, spunt, 'lcd ' + data_dir
		printf, spunt, 'get _processed.txt'
		printf, spunt, 'close'
		printf, spunt, 'exit'
		close, spunt
		free_lun, spunt
		spawn, 'winscp, /script=' + ftp_script

		processed_fname = data_dir + '\_processed.txt'
		nlines = file_lines(processed_fname)
		if nlines eq 0 then begin
			files_processed = ['']
		endif else begin
			files_processed = strarr(nlines)
			openr, handle, processed_fname, /get
			readf, handle, files_processed
			close, handle
			free_lun, handle
		endelse

	;\\ Move all the processed files to the sent directory
		remaining = ['']
		for i = 0, nfiles - 1 do begin
			filename = strupcase(file_basename(files[i]))
			match = where(files_processed eq filename, nmatching)
			if nmatching eq 1 then begin
				printf, log_handle, 'Moving processed file ' + filename + ' to ' + sent_dir
				if not keyword_set(dry_run) then file_move, files[i], sent_dir + '\' + file_basename(files[i])
			endif else begin
				remaining = [remaining, files[i]]
			endelse
		endfor

		if n_elements(remaining) eq 1 then return
		remaining = remaining[1:*]

		printf, log_handle, 'Remaining files:'
		for i = 0, n_elements(remaining) - 1 do printf, log_handle, remaining[i]

		files = remaining
		nfiles = n_elements(remaining)

	;\\ Create a file containing names and checksums of the remaining files (which need to be sent)
		incomming = data_dir + '\' + site + '_incomming.txt'
		file_delete, incomming, /allow_nonexistent
		ftp_script = data_dir + '\SDI_ftp_script.ftp'

		openw, inc_handle, incomming, /get_lun

		for i = 0, nfiles - 1 do begin
			filename = file_basename(files[i])
			print, 'Checksum for: ' + files[i]
			sum = get_md5_checksum(files[i])
			printf, log_handle, 'Checksum ' + filename + ' = ' + sum
			printf, inc_handle, filename + ',' + sum
		endfor

		printf, inc_handle, 'ENDOFFILE' ;\\ check for this on server end
		close, inc_handle
		free_lun, inc_handle

		close, log_handle
		free_lun, log_handle


		;\\ Create the ftp script, split into batches of one file per session (timeout problems)
		files = [files, incomming]
		for i = 0, n_elements(files) - 1 do begin
			openw, ftp_handle, ftp_script, /get_lun
			printf, ftp_handle, 'option echo on'
			printf, ftp_handle, 'option batch abort'
			printf, ftp_handle, 'option confirm off'
			printf, ftp_handle, 'open ' + ftp_command
			printf, ftp_handle, 'lcd c:\users\sdi3000\data\'
			printf, ftp_handle, 'put ' + file_basename(files[i]) + ' instrument_incomming/' + file_basename(files[i])
			printf, ftp_handle, 'close'
			printf, ftp_handle, 'exit'
			close, ftp_handle
			free_lun, ftp_handle

			if keyword_set(dry_run) then begin
				print, 'spawn, winscp /script=' + ftp_script
			endif else begin
				spawn, 'winscp /script=' + ftp_script
			endelse
		endfor

	;\\ Delete the _processed file
		file_delete, processed_fname, /allow_nonexistent

	if keyword_set(dry_run) then begin
		res = dialog_message('Data transfer dry run finished')
	endif

end