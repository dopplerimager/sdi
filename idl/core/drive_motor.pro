

;\\ Wait for a position notification
pro drive_motor_wait_for_position, port, dll_name, com, max_wait_time=max_wait_time, errcode=errcode

	if not keyword_set(max_wait_time) then max_wait_time = 30.	;\\ Max amount of time to wait, in seconds
	errcode = 'p'

	in = ''
	start_time = systime(/sec)
	while strmid(in, 0, 1) ne 'p' do begin
		comms_wrapper, port, dll_name, type=com, /read, data = in
		time_spent = systime(/sec) - start_time
		if time_spent gt max_wait_time then begin
			errcode = 'timeout'
			return
		endif
	endwhile

end


function drive_motor, port, $
					  dll_name, $
					  direction=direction, $
					  gohix=gohix, $
					  goix=goix, $
					  drive_to=drive_to, $
					  control=control, $
					  readpos=readpos, $
					  speed=speed, $
					  accel=accel, $
					  verbatim=verbatim, $
					  home_max_spin_time=home_max_spin_time, $
					  timeout=timeout

	;\\ CONTROL keyword - string "enable"/"disable" enables/disables the motor

	if not keyword_set(accel) then accel = 200
	if not keyword_set(home_max_spin_time) then home_max_spin_time = 3. ; seconds

	com = 'moxa'
	tx = string(13B)
	increments = 5000L

	if not keyword_set(direction) and not keyword_set(goix) and not keyword_set(gohix) and $
	   not keyword_set(drive_to) and not keyword_set(control) and not keyword_set(readpos) and $
	   not keyword_set(verbatim) then return, 0


	;\\ Deal with control calls
		if keyword_set(control) then begin

			case control of
				'openport':begin
					;\\ Open com port
					comms_wrapper, port, dll_name, type=com, /open, moxa_setbaud=12, errcode=errcode
					return, errcode
				end
				'closeport':begin
					;\\ Close com port
					comms_wrapper, port, dll_name, type=com, /close, errcode=errcode
					return, errcode
				end
				'enable':begin
					;\\ Disable Drive
					comms_wrapper, port, dll_name, type=com, /write, data = 'EN' + tx
				end
				'disable':begin
					;\\ Disable Drive
					comms_wrapper, port, dll_name, type=com, /write, data = 'DI' + tx
				end
				'status':begin
					comms_wrapper, port, dll_name, type=com, /write, data = 'GST' + tx
					comms_wrapper, port, dll_name, type=com, /read, data = status
					status = byte(status)
					return, status
				end
				'setpos0':begin
					;\\ Set pos to 0
					comms_wrapper, port, dll_name, type=com, /write, data = 'HO' + tx
				end
				else: return, -1
			endcase

			goto, END_DRIVE_MOTOR
		endif


	;\\ Send verbatim commands straight to the motor, adding a carriage return
		if keyword_set(verbatim) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = verbatim + tx
		endif


	;\\ Handle readpos
		if keyword_set(readpos) then begin
			comms_wrapper, port, dll_name, type=com, /read, data = clear_buffer
			comms_wrapper, port, dll_name, type=com, /write, data = 'POS' + tx
			wait, 0.5
			comms_wrapper, port, dll_name, type=com, /read, data = in_pos
			return, long(in_pos)
		endif


	;\\ Set the maximum speed
		if size(speed, /type) ne 0 then begin
			data_str = 'SP' + string(speed, f='(i0)') + tx
			comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode
		endif


	;\\ Set the acceleration
		data_str = 'AC' + string(accel, f='(i0)') + tx
		comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode


	;\\ If gohix keyword is set then drive to hall zero index position
		if keyword_set(gohix) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'GOHIX' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif

	;\\ If goix keyword is set then drive to limit switch
		if keyword_set(goix) then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'GOIX' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif


	;\\ If drive_to keyword is set, drive to that absolute position
		if size(drive_to, /type) ne 0 then begin
			comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'LA' + string(drive_to, f='(i0)') + tx, errcode=errcode
			comms_wrapper, port, dll_name, type=com, /write, data = 'M' + tx, errcode=errcode
			drive_motor_wait_for_position, port, dll_name, com, max_wait_time = timeout
		endif


	;\\ If direction keyword is set, drive in that direction until blocked. Be sure to set current limits and speed before
	;\\ making this call.
		if keyword_set(direction) then begin

			data_str = 'LR'
			if direction eq 'backwards' then data_str += '-'
			data_str += string(increments, f='(i0)') + tx

			stopped = 0
			while stopped eq 0 do begin

				;\\ Try to turn backwards/forwards by one revolution
					comms_wrapper, port, dll_name, type=com, /write, data = data_str, errcode=errcode

				;\\ Initiate the motion
					comms_wrapper, port, dll_name, type=com, /write, data = 'NP' + tx, errcode=errcode
					comms_wrapper, port, dll_name, type=com, /write, data = 'M' + tx, errcode=errcode
					drive_motor_wait_for_position, port, dll_name, com, max_wait_time = home_max_spin_time, errcode=errcode
					if errcode eq 'timeout' then begin
						print, 'Homing... Timed Out'
						stopped = 1
					endif else begin
						print, 'Homing... Position reached'
					endelse

				wait, 0.01
			endwhile

		endif

END_DRIVE_MOTOR:
comms_wrapper, port, dll_name, type=com, /read, data = clear_buffer
return, 1
end


