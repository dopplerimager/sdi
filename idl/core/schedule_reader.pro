;\\ Code formatted by DocGen


;\D\<Query an SDI schedule file for the next command.>
pro schedule_reader, schedule_file, $                             ;\A\<Schedule file name>
                     schedule_line, $                             ;\A\<The current schedule line>
                     xcomm, $                                     ;\A\<OUT: string command>
                     xargs, $                                     ;\A\<OUT: string array of arguments>
                     lat, $                                       ;\A\<Geographic latitude>
                     lon, $                                       ;\A\<Geographic longitude>
                     console_ref, $                               ;\A\<Object reference for the console>
                     refresh_nm_per_step=refresh_nm_per_step, $   ;\A\<Look for a nm per step refresh command (special syntax)>
                     refresh_phasemap=refresh_phasemap            ;\A\<Look for a phasemap refresh command (special syntax)>


	;\\ If keywords are set, search for the particular control line
		if keyword_set(refresh_nm_per_step) or keyword_set(refresh_phasemap) then begin
			pre_line = schedule_line
			schedule_line = 0
		endif


	nlines = file_lines(schedule_file)
	sched = strarr(nlines)
	temp_str = ''

	openr, file, schedule_file, /get_lun

		for n = 0, nlines - 1 do begin

			readf, file, temp_str
			sched(n) = strtrim(temp_str, 2)

		endfor

	close, file
	free_lun, file


	GET_COMMAND_START:


	if schedule_line lt nlines then begin
		line = sched(schedule_line)
		len = strlen(line)
		blank = 0
		for p = 0, len - 1 do begin
			if strmid(line,p,1) ne ' ' then blank = blank + 1
		endfor
		if blank eq 0 then begin
			schedule_line = schedule_line + 1
			goto, GET_COMMAND_START
		endif
	endif else begin
		command = 'EOF'
		goto, END_SCHEDULE
	endelse

	str = ''
	command = ''

	;\\ Get the command for the current line
		for pos = 0, len - 1 do begin
			str = strmid(line, pos, 1)
			if str ne ' ' and byte(str) ne 9 then begin
				if str eq '#' then begin
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif
				if str eq ':' then break
				if str eq '%' and not keyword_set(refresh_nm_per_step) then begin
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif
				if str eq '&' and not keyword_set(refresh_phasemap) then begin
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif
				command = command + str
			endif
		endfor


	;\\ Perform refresh check
		if keyword_set(refresh_nm_per_step) then begin
			if strmid(command,0,2) eq '%%' then begin
				command = strmid(command, 2, strlen(command)-2)

			endif else begin
				schedule_line = schedule_line + 1
				goto, GET_COMMAND_START
			endelse
		endif

		if keyword_set(refresh_phasemap) then begin
			if strmid(command,0,2) eq '&&' then begin
				command = strmid(command, 2, strlen(command)-2)
			endif else begin
				schedule_line = schedule_line + 1
				goto, GET_COMMAND_START
			endelse
		endif

		last_pos = pos + 1
		argc = 0

	;\\ Get the number of args
		for p = 0, len - 1 do begin
			if strmid(line, p, 1) eq ',' then argc = argc + 1
		endfor

		argc = argc + 1
		last_pos = pos + 1
		args = strarr(argc)
		this_arg = 0

	;\\ Get the arguments
		if pos lt len then begin
			for pos = last_pos, len - 1 do begin
				str = strmid(line, pos, 1)
				;\\ For spectra commands, filename is given as a format string,
				;\\ so need to keep spaces:
				if str eq '`' then begin

					sub_pos = pos + 1
					str = strmid(line, sub_pos, 1)
					while str ne '`' do begin
						if this_arg lt argc then args(this_arg) = args(this_arg) + str
						sub_pos = sub_pos + 1
						str = strmid(line, sub_pos, 1)
					endwhile
					break
				endif
				if str ne ' ' and byte(str) ne 9 then begin
					if str ne ',' and str ne ']' and str ne '[' then begin
						if this_arg lt argc then args(this_arg) = args(this_arg) + str
					endif else begin
						if str eq ']' then break
						if str ne '[' then this_arg = this_arg + 1
					endelse
				endif
			endfor
		endif


	;\\ Handle ifsea commands
		if command eq 'ifsea' then begin

			command = 'control'
			true = 0
			min_angle = float(args(0))
			max_angle = float(args(1))

			arg_str = ''
			last_pos = pos + 1
			if pos lt len then begin
				for pos = last_pos, len - 1 do begin
					str = strmid(line, pos, 1)
					if str ne ' ' and byte(str) ne 9 then begin
						if str eq '[' then begin
							while str ne ']' do begin
								pos = pos + 1
								str = strmid(line, pos, 1)
								if str ne ']' then arg_str = arg_str + str
							endwhile
							break
						endif
					endif
				endfor
			endif

			full_time = bin_date(systime())
			time = full_time(3) + full_time(4)/60. + full_time(5)/3600.

			current_sea = get_sun_elevation(lat, lon)

			if current_sea gt min_angle and current_sea lt max_angle then true = 1

			if arg_str eq 'cont' then begin
				if true eq 1 then begin
					;\\ Condition met, so continue reading schedule
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif else begin
					;\\ Condition not met, find next ifsea command and continue from next line
					pts = where(strmid(sched,0,5) eq 'ifsea', npts)
					this_pt = where(pts eq schedule_line)
					schedule_line = pts(this_pt(0) + 1) + 1
					goto, GET_COMMAND_START
				endelse
			endif

			if arg_str eq 'loop' then begin
				if true eq 1 then begin
					;\\ Condition met, so loop to previous ifsea command
					pts = where(strmid(sched,0,5) eq 'ifsea', npts)
					this_pt = where(pts eq schedule_line)
					schedule_line = pts(this_pt(0) - 1) + 1
					goto, GET_COMMAND_START
				endif else begin
					;\\ Condition not met, continue from next line
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endelse
			endif

		endif


	;\\ Handle ifut commands
		if command eq 'ifut' then begin

			command = 'control'
			true = 0
			min_ut = float(args(0))
			max_ut = float(args(1))

			arg_str = ''
			last_pos = pos + 1
			if pos lt len then begin
				for pos = last_pos, len - 1 do begin
					str = strmid(line, pos, 1)
					if str ne ' ' and byte(str) ne 9 then begin
						if str eq '[' then begin
							while str ne ']' do begin
								pos = pos + 1
								str = strmid(line, pos, 1)
								if str ne ']' then arg_str = arg_str + str
							endwhile
							break
						endif
					endif
				endfor
			endif

			full_time = bin_date(systime(/ut))
			current_ut = full_time[3] + full_time[4]/60. + full_time[5]/3600.
			if current_ut gt min_ut and current_ut lt max_ut then true = 1

			if arg_str eq 'begin' then begin
				if true eq 1 then begin
					;\\ Condition met, so continue reading schedule
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif else begin
					;\\ Condition not met, find next ifut command and continue from next line
					pts = where(strmid(sched,0,4) eq 'ifut', npts)
					this_pt = where(pts eq schedule_line)
					schedule_line = pts(this_pt(0) + 1) + 1
					goto, GET_COMMAND_START
				endelse
			endif

			if arg_str eq 'end' then begin
				schedule_line = schedule_line + 1
				goto, GET_COMMAND_START
			endif

		endif


	;\\ Handle ifsnr commands
		if command eq 'ifsnr' then begin

			command = 'control'
			true = 0
			min_snr = float(args(0))
			max_snr = float(args(1))

			snr = console_ref->get_snr_per_scan()
			if snr ge min_snr and snr lt max_snr then true = 1

			arg_str = ''
			last_pos = pos + 1
			if pos lt len then begin
				for pos = last_pos, len - 1 do begin
					str = strmid(line, pos, 1)
					if str ne ' ' and byte(str) ne 9 then begin
						if str eq '[' then begin
							while str ne ']' do begin
								pos = pos + 1
								str = strmid(line, pos, 1)
								if str ne ']' then arg_str = arg_str + str
							endwhile
							break
						endif
					endif
				endfor
			endif

			if arg_str eq 'begin' then begin
				if true eq 1 then begin
					;\\ Condition met, so continue reading schedule
					schedule_line = schedule_line + 1
					goto, GET_COMMAND_START
				endif else begin
					;\\ Condition not met, find next ifsnr command and continue from next line
					pts = where(strmid(sched,0,5) eq 'ifsnr', npts)
					this_pt = where(pts eq schedule_line)
					schedule_line = pts(this_pt(0) + 1) + 1
					goto, GET_COMMAND_START
				endelse
			endif

			if arg_str eq 'end' then begin
				schedule_line = schedule_line + 1
				goto, GET_COMMAND_START
			endif

		endif


	END_SCHEDULE:

		if command ne 'control' and command ne 'EOF' then begin
			schedule_line = schedule_line + 1
			xcomm = strlowcase(command)
			xargs = args
		endif else begin
			xcomm = strlowcase(command)
			xargs = 0
		endelse

end
