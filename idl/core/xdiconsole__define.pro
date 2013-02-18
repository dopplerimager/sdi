;\\ Code formatted by DocGen


;\D\<The console initialization routine. See the SDI software manual for a description of>
;\D\<what this function does.>
function XDIConsole::init, schedule=schedule, $       ;\A\<The schedule file name>
                           mode=mode, $               ;\A\<Mode to run in - "auto" or "manual" (default)>
                           settings=settings, $       ;\A\<The console settings file (required)>
                           start_line=start_line      ;\A\<Optional start line in the schedule file>

	;\\ Keep a list of things to log, once the log is set up
	log_queue = ['']

	;\\ Fill out the default values here
	xdisettings_template, etalon=def_etalon, $
						  camera=def_camera, $
						  header=def_header, $
						  logging=def_logging, $
						  misc=def_misc
	self.etalon = def_etalon
	self.camera = def_camera
	self.header = def_header
	self.logging = def_logging
	self.misc = def_misc

	;\\ Manual mode by default
	if not keyword_set(mode) then mode = 'manual'

	;\\ Make sure we have  schedule file if starting up in auto mode
	if keyword_set(mode) then begin
		if mode eq 'auto' and not keyword_set(schedule) then begin
			res = dialog_message('No schedule file for auto mode - switching to manual mode.')
			mode = 'manual'
		endif
	endif

	if not keyword_set(schedule) then schedule = ''

	;\\ If no settings file was provided, the default settings will be used.
	;\\ Warn about this, and set the settings field in self.runtime to something
	;\\ that allows to check whether a settings file was provided.
    if not keyword_set(settings) then begin
    	log_queue = [log_queue, 'No settings file specified, using default settings!']
    	settings = '__no_settings_file_provided__'
    endif

	if not keyword_set(start_line) then begin
		self.misc.schedule_line = 0
	endif else begin
		self.misc.schedule_line = start_line
	endelse


	;\\ Store the runtime settings
		self.runtime.schedule = schedule
		self.runtime.settings = settings
		self.runtime.mode     = strlowcase(mode)
		self.runtime.current_status = 'No status'
		self.runtime.last_schedule_command = 'None'


	;\\ Find and store plugins
		paths = Get_Paths()
		self.runtime.plugin_path_list = file_search(paths + '\SDI*__define.pro', count = nmods)
		if nmods gt 0 then begin
			for n = 0, nmods - 1 do begin
				str = self.runtime.plugin_path_list(n)
				pos = 0
				start = 0
				while pos lt strlen(str) do begin
					if strmid(str,pos,1) eq '\' then start = pos + 1
					pos = pos + 1
				endwhile
				self.runtime.plugin_name_list(n) = strlowcase(strmid(str, (start + 3), (strlen(str)-15) - start))
				self.runtime.plugin_name_list(n) = strupcase(strmid(self.runtime.plugin_name_list(n),0,1)) + strmid(self.runtime.plugin_name_list(n),1,strlen(self.runtime.plugin_name_list(n))-1)
			endfor
		endif


	;\\ Generate the SDI Console
		xs = 550
		ys = 435
		title = 'SDI CONSOLE'
		self.misc.console_id = widget_base(mbar = menu, title=title, tracking_events = 0, col=1)

		file_menu  = widget_button(menu, value = 'File', /menu)
		cam_menu   = widget_button(menu, value = 'Camera', /menu)
		eta_menu   = widget_button(menu, value = 'Etalon', /menu)
		mot_menu   = widget_button(menu, value = 'Motors', /menu)
		set_menu   = widget_button(menu, value = 'Settings', /menu)

		if self.runtime.mode eq 'manual' then swap = 'Auto' else swap = 'Manual'
		file_bttn3 = widget_button(file_menu, value = 'Switch to ' + swap + ' Mode',  uvalue = {tag:'mode_switch'}, uname = 'Console_mode_switch')
		file_bttn4 = widget_button(file_menu, value = 'List Plugins', uvalue = {tag:'file_show'})
		file_bttn5 = widget_button(file_menu, value = 'View Schedule', uvalue = {tag:'file_show_sched'})
		file_bttn6 = widget_button(file_menu, value = 'Change Schedule', uvalue = {tag:'file_change_sched'})
		file_bttn7 = widget_button(file_menu, value = 'Re-Initialize', uvalue = {tag:'file_re_initialize'})

		cam_bttn1  = widget_button(cam_menu,  value = 'Temperature',    uvalue = {tag:'cam_temp', force:1})
		cam_bttn2  = widget_button(cam_menu,  value = 'Status',      	uvalue = {tag:'cam_status'})
		cam_bttn3  = widget_button(cam_menu,  value = 'Cooler',        	uvalue = {tag:'cam_cooler'})
		cam_bttn4  = widget_button(cam_menu,  value = 'Exp. Time',    	uvalue = {tag:'cam_exptime'})
		cam_bttn5  = widget_button(cam_menu,  value = 'Gain',        	uvalue = {tag:'cam_gain'})
		cam_bttn6  = widget_button(cam_menu,  value = 'Close Shutter', 	uvalue = {tag:'cam_shutterclose'})
		cam_bttn7  = widget_button(cam_menu,  value = 'Open Shutter', 	uvalue = {tag:'cam_shutteropen'})
		cam_bttn8  = widget_button(cam_menu,  value = 'Shutdown',    	uvalue = {tag:'cam_shutdown'})
		cam_bttn9  = widget_button(cam_menu,  value = 'Initialize',    	uvalue = {tag:'cam_initialize'})

		eta_bttn2  = widget_button(eta_menu,  value = 'View Calibration',   	uvalue = {tag:'see_calibration'})

		mot_bttn1  = widget_button(mot_menu,  value = 'Home Sky Pos',   uvalue = {tag:'mot_home_sky'})
		mot_bttn2  = widget_button(mot_menu,  value = 'Home Cal Pos',   uvalue = {tag:'mot_home_cal'})
		mot_bttn3  = widget_button(mot_menu,  value = 'Drive Sky Pos',   uvalue = {tag:'mot_drive_sky'})
		mot_bttn4  = widget_button(mot_menu,  value = 'Drive Cal Pos',   uvalue = {tag:'mot_drive_cal'})
		mot_bttn4  = widget_button(mot_menu,  value = 'Drive Mirror To Pos',   uvalue = {tag:'mot_drive_mirror_to'})
		mot_bttn5  = widget_button(mot_menu,  value = 'Select Filter',   uvalue = {tag:'mot_sel_filter'})
		mot_bttn6  = widget_button(mot_menu,  value = 'Select Cal Source',   uvalue = {tag:'mot_sel_cal', type:'drive'})
		mot_bttn6  = widget_button(mot_menu,  value = 'Home Cal Source',   uvalue = {tag:'mot_sel_cal', type:'home'})

		set_bttn1  = widget_button(set_menu,  value = 'Load settings',  uvalue = {tag:'load_settings'})
		set_bttn1  = widget_button(set_menu,  value = 'Load settings (full restore)',  uvalue = {tag:'load_settings_full'})
		set_bttn1  = widget_button(set_menu,  value = 'Re-Load current settings',  uvalue = {tag:'reload_settings'})
		set_bttn2  = widget_button(set_menu,  value = 'Show current settings',  uvalue = {tag:'show_current_settings'})
		set_bttn1  = widget_button(set_menu,  value = 'Write settings',  uvalue = {tag:'write_settings'})
		set_bttn4  = widget_button(set_menu,  value = 'Close Mirror Port',  uvalue = {tag:'close_mport'})
		set_bttn4  = widget_button(set_menu,  value = 'Open Mirror Port',  uvalue = {tag:'open_mport'})

		;\\ Make a view for the log
		self.misc.log_id = widget_text(self.misc.console_id, xsize=65, ysize = 18, /scroll, font = 'Tahoma*Bold*15', /align_center)

		gauge_base = widget_base(self.misc.console_id, col = 2, /align_center, /frame)
		font = 'Arial*Bold*15'

		xs = 270
		temp_guage = widget_label(gauge_base, value = 'Temperature: ', font=font, uname = 'console_temp_guage', xs = xs)
		sea_guage  = widget_label(gauge_base, value = 'Sun Elev.: ', font=font, uname = 'console_sea_guage', xs = xs)
		exp_time_guage  = widget_label(gauge_base, value = 'Exp Time: ', font=font, uname = 'console_exp_time_guage', xs = xs)
		gain_guage  = widget_label(gauge_base, value = 'Gain: ', font=font, uname = 'console_gain_guage', xs = xs)
		shutter_guage  = widget_label(gauge_base, value = 'Shutter: ', font=font, uname = 'console_shutter_guage', xs = xs)
		motor_pos_guage  = widget_label(gauge_base, value = 'MirrorPos: ', font=font, uname = 'console_motor_guage', xs = xs)
		switch_pos_guage  = widget_label(gauge_base, value = 'SwitchPos: ', font=font, uname = 'console_switch_guage', xs = xs)
		filter_pos_guage  = widget_label(gauge_base, value = 'Filter Num: ', font=font, uname = 'console_filter_guage', xs = xs)
		frame_rate_guage  = widget_label(gauge_base, value = 'Frame Rate: ', font=font, uname = 'console_frame_guage', xs = xs)

		lower_base = widget_base(self.misc.console_id, col=2)

		reload_button = widget_button(lower_base, font=font, value='Reload Settings', ys=50, $
									   uvalue = {tag:'reload_settings'}, /align_center)

		leg_base = widget_base(lower_base, col = 1, /align_center)

		xs = 600
		leg1bar  = Widget_Draw(leg_base, xsize= 0.7*xs, ysize = 0.03*ys, frame=1, uname = 'console_leg1_bar')
		leg2bar  = Widget_Draw(leg_base, xsize= 0.7*xs, ysize = 0.03*ys, frame=1, uname = 'console_leg2_bar')
		leg3bar  = Widget_Draw(leg_base, xsize= 0.7*xs, ysize = 0.03*ys, frame=1, uname = 'console_leg3_bar')
		leglab   = widget_label(leg_base, frame=0, value = "Leg Voltages: ", font=font)

	;\\ Include the list of SDI modules in the menu
		if nmods gt 0 then begin
			module_menu = widget_button(menu, value = 'Modules', /menu)
			module_menu_list = lonarr(nmods)
			for n = 0, (nmods - 1) do begin
				module_menu_list(n) = widget_button(module_menu, value = self.runtime.plugin_name_list(n), uvalue = {tag:'start_plugin', name:self.runtime.plugin_path_list(n)})
			endfor
		endif

	;\\ Create the timer widget
		self.misc.timer_id  = widget_base(self.misc.console_id, map = 0, uval = 'Timer')

	;\\ Realize the console
		widget_control, self.misc.console_id, /realize

		;\\ Output any accumulated log messages
		for i = 1, n_elements(log_queue) - 1 do begin
			self->log, log_queue[i], 'Console', /display
		endfor

	;\\ Create an instance of the manager class
		self.manager = obj_new('XDIWidgetReg', id = self.misc.console_id, ref = self)

	;\\ Load the settings file
		self -> load_settings, 0, filename = settings, error = error, first_call = 1

	;\\ Make sure file loaded correctly, else prompt for a new file or end
		if self.runtime.mode eq 'manual' then begin
			while error ne 0 do begin
				fname = dialog_pickfile(path = self.misc.default_settings_path)
				if fname eq '' then begin
					widget_control, /destroy, self.misc.console_id
					return, 0
				endif else begin
					self.runtime.settings = fname
					self -> load_settings, 0, filename = settings, error = error
				endelse
			endwhile
		endif else begin
			if error ne 0 then begin
				print, 'Settings file loaded incorrectly. Ending.'
				widget_control, /destroy, self.misc.console_id
				return, 0
			endif
		endelse

	;\\ Modify the title to indicate a manual or auto session
		title = 'SDI CONSOLE - ' + self.header.instrument_name + ' - Mode: ' + self.runtime.mode
		widget_control, self.misc.console_id, base_set_title = title

	;\\ Load the console specific settings file (each plugin has one, usually describing widget geometry)
		if file_test(self.misc.default_settings_path + 'console.sdi') then begin
			restore, self.misc.default_settings_path + 'console.sdi', /relaxed
			widget_control, xo = geometry.xoffset, yo = geometry.yoffset, self.misc.console_id
		endif

	;\\ Compile the instrument specific file
		resolve_routine, self.header.instrument_name + '_initialise', /compile_full_file

	;\\ Call the instrument specific initialisation routine
		call_procedure, self.header.instrument_name + '_initialise', self.misc, self

	;\\ Initialise the camera
		status = 0
		res = get_error(call_external(self.misc.dll_name, 'uGetStatus', status))
		if res eq 'DRV_NOT_INITIALIZED' then begin
			self->log, 'Initializing camera: ' + get_error(call_external(self.misc.dll_name, 'uInitialize', 'c:\testcode')), 'Console', /display
		endif else begin
			self->log, 'Camera already initialized', 'Console', /display
		endelse

	;\\ Update the camera (usually done automatically, but not during startup)
		commands = ['uSetShutter', 'uSetReadMode', 'uSetImage', 'uSetAcquisitionMode', $
		            'uSetFrameTransferMode', 'uSetEMGainMode', 'uSetPreAmpGain', 'uSetVSAmplitude', $
		            'uSetBaselineClamp', 'uSetADChannel', 'uSetOutputAmplifier', 'uSetTriggerMode', 'uSetHSSpeed', $
					'uSetVSSpeed', 'uSetExposureTime', 'uSetTemperature', 'uGetTemperatureRange', 'uSetGain', 'uSetFanMode']
		if self.camera.cooler_on eq 1 then commands = [commands, 'uCoolerON'] else commands = [commands, 'uCoolerOFF']
		self -> update_camera, commands, results

		res = call_external(self.misc.dll_name, 'uStartAcquisition')

	;\\ Ensure the timer tick interval is greater than zero
		if self.misc.timer_tick_interval eq 0.0 then self.misc.timer_tick_interval = 0.0

	;\\ Make a palette
		load_pal, culz, idl = [3,1]
		self.misc.palette = culz

	;\\ Read the mirror position
		pos = 0
		call_procedure, self.header.instrument_name + '_mirror', read_pos = pos,  self.misc, self
		widget_control, set_value = 'MirrorPos: ' + string(res,f='(i0)'), motor_pos_guage

	;\\ Update the current filter number
		filter = self.misc.current_filter
		widget_control, set_value = 'Filter Num: ' + string(filter,f='(i0)'), filter_pos_guage

	;\\ Register with the Manager object for timer events
		self.manager -> register, self.misc.console_id, self, 'Console', 0, 1, 0

	;\\ Compile modules for restoration purposes
		compile_list = 'sdi' + self.runtime.plugin_name_list + '__define'
		resolve_routine, compile_list

	;\\ Start the timer
		widget_control, self.misc.timer_id,  timer = self.misc.timer_tick_interval

	;\\ Set the event handler
		xmanager, 'console_base', self.misc.console_id, event_handler = 'Handle_Event', cleanup = 'Kill_Entry', /no_block

	return, 1

end

;\D\<Widget events get re-routed from the sdi\_main.pro to here. If the event is a tiemr event,>
;\D\<the timer\_event method in those plugins which are registered to receive timer events>
;\D\<(which includes the console itself) is called. For other events (for example a user clicks>
;\D\<a button in a plugin) they are sent to their appropriate plugin.>
pro XDIConsole::Event_Handler, event  ;\A\<Widget event>

	;\\ TIMER EVENT

	if event.id eq self.misc.timer_id then begin

		if self.manager -> count_objects() gt 0 then begin
			struc = self.manager -> generate_list()
			instances = where(struc.need_timer eq 1, ntimers)

			if ntimers gt 0 then begin
				for x = 0, ntimers - 1 do begin
					struc.ref(instances(x)) -> timer_event
				endfor
			endif
		endif

		widget_control, self.misc.timer_id, timer = self.misc.timer_tick_interval
		goto, EVENT_SKIP

	endif


	;\\ OTHER EVENT

	tags = tag_names(event)
	match = where(strlowcase(tags) eq 'tag', matchyn)

	if matchyn eq 1 then begin
		uval_struc = {tag:'editor_closed'}
	endif else begin
		widget_control, get_uvalue = uval_struc, event.id
		widget_control, get_value = val, event.id
	endelse

	if size(uval_struc, /type) eq 8 then begin
		uval = uval_struc.tag
		id = event.top
		if uval eq 'image_capture' or uval eq 'editor_closed' then begin
			obj = self
		endif else begin
			obj = self.manager -> match_register_ref(id)
		endelse
		call_method, uval, obj, event
	endif

EVENT_SKIP:
end

;\D\<Widget destruction events are re-routed from the sdi\_main.pro handler to here. This>
;\D\<function checks to see if we are destroying the whole hierarchy (if the user closed the>
;\D\<console) or just a single plugin. Before destroying a plugin, this function checks to see>
;\D\<if that plugin requires any of its settings to be saved, and if so, gets the widget manager>
;\D\<object to save those settings. If the whole hierarchy is being destroyed, this function>
;\D\<attempts to shut down the camera. If cooling is on, a flag is set which tells the console>
;\D\<to wait for the temperature to go above a safe temperature (0 degrees C i think) before>
;\D\<actually terminating. This check is done inside the timer\_event method.>
pro XDIConsole::Kill_Handler, id, $                        ;\A\<Widget id>
                              kill_widget=kill_widget      ;\A\<Flag to indicate widget is to be destroyed>

;\\ info.kill = 1 means the whole heirarchy is being destroyed (end of session)

	kill = 0

	if id eq self.misc.console_id then kill = kill + 1

	if id ne self.misc.console_id and kill eq 0 then begin

		obj = self.manager -> match_register_ref(id)
		type = self.manager -> match_register_type(id)
		store = self.manager -> match_register_store(id)

		if store eq 1 then self.manager -> save_settings, self.misc.default_settings_path, id, strlowcase(type), obj
		if store eq 1 then obj_destroy, obj, 1

		self.manager -> delete_instance, id

		if keyword_set(kill_widget) then widget_control, /destroy, id

	endif

	if kill eq 1 then begin

		if self.misc.shutdown_on_exit eq 1 then self -> cam_shutdown, 'console closed'

		if self.camera.wait_for_shutdown eq 1 then goto, SKIP_KILL

		num = self.manager -> count_objects()

		if num gt 0 then begin

			struc = self.manager -> generate_list()

			for x = 0, (n_elements(struc.id) - 1) do begin
				if struc.store(x) eq 1 then self.manager -> save_settings, self.misc.default_settings_path, struc.id(x), strlowcase(struc.type(x)), struc.ref(x)
				self.manager -> delete_instance, struc.id(x)
				if struc.store(x) eq 1 then obj_destroy, struc.ref(x), 0
				if struc.store(x) eq 1 then widget_control, struc.id(x), /destroy
			endfor

		endif

		heap_free, self.manager, /verbose
		obj_destroy, self

	endif


SKIP_KILL:
end

;\D\<Timer events are processed here, this involves checking the camera for new images, updating>
;\D\<solar elevation angle etc, incrementing the scan channel if a new image arrived, passing>
;\D\<new images onto to registered plugins, and checking to see if a new schedule command is required.>
pro XDIConsole::timer_event

	common console_images, image, img_buf
	common mc_timesaver, numav, mc_start, frame_rate

	status = 0
	res = call_external(self.misc.dll_name, 'uGetStatus', status)

	template_image = *self.buffer.image
	x_dim = n_elements(template_image(*,0))
	y_dim = n_elements(template_image(0,*))

	if n_elements(image) eq 0   then image = lonarr(x_dim,y_dim)
	if n_elements(img_buf) eq 0 then img_buf = lonarr(x_dim,y_dim)
	im_size = ulong(float(x_dim) * float(y_dim))


	;\\ Delete the crash file if it is there
		crash_file = 'c:\users\sdi3000\sdi\watchdog\console_crash_file.tmp'
		if file_test(crash_file) then file_delete, crash_file, /quiet

	;\\ Update solar elevation angle, shutter state, temp, filter num
		sea = get_sun_elevation(self.header.latitude, self.header.longitude)
		if self.runtime.shutter_state eq 0 then shutter_string = 'CLOSED' else shutter_string = 'OPEN'
		shutter_id = widget_info(self.misc.console_id, find_by_uname = 'console_shutter_guage')
		temp_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_temp_guage')
		sea_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_sea_guage')
		filter_guage_id = widget_info(self.misc.console_id, find_by_uname='console_filter_guage')

		widget_control, set_value = 'Sun Elev.: ' + string(sea, f='(f0.3)'), sea_guage_id
		widget_control, set_value = 'Shutter: ' + shutter_string, shutter_id
		widget_control, set_value = 'Filter Num: ' + string(self.misc.current_filter, f='(i0)'), filter_guage_id

	;\\ Send back status info every 10 minutes
		self->status_update


	;\\ Check to see if a new day has started, if so, create a settings file backup
		current_daynumber = fix(dt_tm_mk(systime(/jul), f='doy$'))
		if current_daynumber ne self.runtime.current_daynumber then begin
			backup_dir = self.misc.default_settings_path + '\BackupSettings\'
			file_mkdir, backup_dir
			self.runtime.current_daynumber = current_daynumber
			fname_backup = backup_dir + file_basename(self.runtime.settings) + '_BACKUP_' + dt_tm_mk(systime(/jul), f='Y$_0n$_0d$')
			pfname_backup = backup_dir + 'persistent_BACKUP_' + dt_tm_mk(systime(/jul), f='Y$_0n$_0d$')
			self->save_current_settings, filename=fname_backup, pfilename=pfname_backup
			print, 'Saved Backup Files: ' + fname_backup + ', ' + pfname_backup
		endif


	;   MC Mod for Mode 5 (run to abort) operation <<<<<<<<<<<
		firstim = 0L
		lastim  = 0L
		res = get_error(call_external(self.misc.dll_name, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))

		if res eq 'DRV_SUCCESS' and (lastim - firstim) eq 47 then begin
			resx = call_external(self.misc.dll_name, 'uAbortAcquisition')
			resx = call_external(self.misc.dll_name, 'uStartAcquisition')
			firstim = lastim
			print, 'Aborted/Restarted - ' + systime()
		endif

	;\\ This lets the console keep updating things like solar zenith angle,
	;\\ and so on, and gives plugins empty images, so that everything goes on as normal
	;\\ even if the camera is shutdown (in hibernation over summer!)
		if res eq 'DRV_NOT_INITIALIZED' then begin

			xpix = self.camera.xpix
			ypix = self.camera.ypix

			image = fltarr(xpix/self.camera.xbin, ypix/self.camera.ybin)
			self.camera.temp_state = 'CAMERA IS SHUT DOWN!!'
			widget_control, set_value = self.camera.temp_state, temp_guage_id

			;\\ Calculate frame rate in Hz and update guage
			self.runtime.acquire_time = systime(/sec) - self.runtime.acquire_start
			frame_rate = (1. / self.runtime.acquire_time)
			frame_guage_id = widget_info(self.misc.console_id, find_by_uname='console_frame_guage')
			widget_control, set_value = 'Frame Rate: ' + string(frame_rate, f='(f0.3)'), frame_guage_id
			self.runtime.acquire_start = systime(/sec)
			status = 20073
		endif

	if (firstim ne lastim) or get_error(status) eq 'DRV_IDLE' then begin

		;\\ If DRV_IDLE in mode 5, need a restart acquisition command
		if self.camera.acquisition_mode eq 5 and get_error(status) eq 'DRV_IDLE' then begin
			res = call_external(self.misc.dll_name, 'uStartAcquisition')
		endif


			;\\ Get temp
				if self.camera.temp_state ne 'CAMERA IS SHUT DOWN!!' then begin
					if self.camera.acquisition_mode eq 1 then begin
						temp = 0.0;
						res = call_external(self.misc.dll_name, 'uGetTemperatureF', temp, val=[0b])
						self.camera.cam_temp = temp
						self.camera.temp_state = get_error(res)
						widget_control, set_value = 'Temperature: ' + string(temp, f='(f0.3)') + ' - ' + $
									self.camera.temp_state, temp_guage_id
					endif else begin
						temp = self.camera.cam_temp
						temp_state = self.camera.temp_state
						widget_control, set_value = 'Temperature: ' + string(temp, f='(f0.3)') + ' - ' + $
									self.camera.temp_state + ' NOT UPDATED!', temp_guage_id
					endelse

				;\\ Check for camp temp and shutdown wait status
					if temp gt self.camera.cam_safe_temp then begin
						;\\ Only the camera is being shutdown
						if self.camera.wait_for_min_temp eq 1 and self.camera.wait_for_shutdown eq 0 then begin
							self -> cam_shutdown, 0
						endif
						;\\ Camera and console are both being shutdown
						if self.camera.wait_for_min_temp eq 1 and self.camera.wait_for_shutdown eq 1 then begin
							self.camera.wait_for_shutdown = 0
							self -> Kill_Handler, self.misc_console_id
						endif
					endif
				endif


			;\\ Get the most recent image. (Heavily modified by MC) <<<<<<<<<<<<<<<
				if self.camera.temp_state ne 'CAMERA IS SHUT DOWN!!' then begin
					if self.camera.acquisition_mode eq 5 then begin
;					    img_buf = lonarr(size(image, /dim))
					    nframes = 0
		                repeat begin
	  						res = call_external(self.misc.dll_name, 'uGetOldestImage', img_buf, im_size)
	  						if nframes eq 0 then image = 4*img_buf else image = image + 4*img_buf
;						print, "New image: ", nframes, min(img_buf), max(img_buf)
	  						nframes = nframes + 1
	  						firstim = 0L
	  						lastim = 0L
	  						res = get_error(call_external(self.misc.dll_name, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))
						endrep until firstim eq lastim

						image = (image)/nframes
						*self.buffer.raw_image = ulong(image)
						call_procedure, self.header.instrument_name + '_imageprocess', image
						*self.buffer.image = ulong(image)

						;\\ Calculate frame rate in Hz and update guage
							self.runtime.acquire_time = systime(/sec) - self.runtime.acquire_start

							if n_elements(frame_rate) eq 0 then frame_rate = 0.
							if n_elements(numav) eq 0 then begin
								numav = 0
								mc_start = systime(/sec)
								frame_rate = 0
							endif else begin
								if numav lt 15 then numav = numav + 1 else begin
									frame_rate = numav/(systime(/sec) - mc_start)
									mc_start = systime(/sec)
									numav = 0
								endelse
							endelse

							frame_guage_id = widget_info(self.misc.console_id, find_by_uname='console_frame_guage')
							widget_control, set_value = 'Frame Rate: ' + string(frame_rate, f='(f0.3)'), frame_guage_id
							self.runtime.acquire_start = systime(/sec)

					endif else begin

						res = call_external(self.misc.dll_name, 'uGetMostRecentImage', image, im_size)

						*self.buffer.raw_image = ulong(image)
						call_procedure, self.header.instrument_name + '_imageprocess', image
						*self.buffer.image = ulong(image)

						;\\ Calculate frame rate in Hz and update guage
							self.runtime.acquire_time = systime(/sec) - self.runtime.acquire_start
							frame_rate = (1. / self.runtime.acquire_time)
							frame_guage_id = widget_info(self.misc.console_id, find_by_uname='console_frame_guage')
							widget_control, set_value = 'Frame Rate: ' + string(frame_rate, f='(f0.3)'), frame_guage_id
							self.runtime.acquire_start = systime(/sec)
						;\\ Sometimes camera 'hangs up' in mode 1 (very very very infrequently) so check for this
							if self.runtime.acquire_time gt 30.*self.camera.exposure_time then begin
								print, 'Acquire time > 30 x Exp_time, erstarting acquisition!'
								res = call_external(self.misc.dll_name, 'uAbortAcquisition')
								;\\ Restart occurs after leg update
							endif
					endelse
				endif


			;\\ Check for motor homing
				if self.runtime.homing_motors eq 1 then begin
					self -> mot_home_source, image
				endif


			channel = self.etalon.current_channel
			clear_active = 0

			;\\ If still scanning, increment channel and adjust legs
				if self.etalon.scanning eq 1 then begin
					if self.etalon.start_volt_offset ne 0 and self.etalon.stop_volt_offset ne 0 then begin
						;\\ This must be a partial scan (like a steps/order calc)
							nsteps = fix((self.etalon.stop_volt_offset - self.etalon.start_volt_offset)/self.etalon.volt_step_size)
							if self.etalon.current_channel lt (nsteps-1) then begin
								self.etalon.current_channel = self.etalon.current_channel + 1
								self -> update_legs
							endif else begin
								;\\ Stop the scanner
									self -> scan_etalon, 'Console', /stop_scan
							endelse
					endif else begin
						;\\ Full scan over one order, step_size = steps/order
							if self.etalon.current_channel lt (self.etalon.number_of_channels-1) then begin
								self.etalon.current_channel = self.etalon.current_channel + 1
								self -> update_legs
							endif else begin
							   	;\\ Stop the scanner
									self -> scan_etalon, 'Console', /stop_scan
							endelse
					endelse
				endif

;------------------------------------------------------
;-------Update the bars for each of the 3 leg voltages:
		leg1bar = widget_info(self.misc.console_id, find_by_uname='console_leg1_bar')
		leg2bar = widget_info(self.misc.console_id, find_by_uname='console_leg2_bar')
		leg3bar = widget_info(self.misc.console_id, find_by_uname='console_leg3_bar')

		Widget_Control, leg1bar, Get_Value=wid
		wset, wid
		fracy = float(self.etalon.leg1_voltage)/self.etalon.max_voltage
		if channel eq 0 then Polyfill, [0.0, 0.0, 1.0, 1.0, 0.0],  [0.0, 1., 1, 0.0, 0.0], /normal, color=self.misc.palette.wheat
		Polyfill, [0.0, 0.0, fracy, fracy, 0.0], [0.0, 1.0, 1.0, 0.0, 0.0], /normal, Color=self.misc.palette.slate

		Widget_Control, leg2bar, Get_Value=wid
		wset, wid
		fracy = float(self.etalon.leg2_voltage)/self.etalon.max_voltage
		if channel eq 0 then Polyfill, [0.0, 0.0, 1.0, 1.0, 0.0],  [0.0, 1., 1, 0.0, 0.0], /normal, color=self.misc.palette.wheat
		Polyfill, [0.0, 0.0, fracy, fracy, 0.0], [0.0, 1.0, 1.0, 0.0, 0.0], /normal, Color=self.misc.palette.slate

		Widget_Control, leg3bar, Get_Value=wid
		wset, wid
		fracy = float(self.etalon.leg3_voltage)/self.etalon.max_voltage
		if channel eq 0 then Polyfill, [0.0, 0.0, 1.0, 1.0, 0.0],  [0.0, 1., 1, 0.0, 0.0], /normal, color=self.misc.palette.wheat
		Polyfill, [0.0, 0.0, fracy, fracy, 0.0], [0.0, 1.0, 1.0, 0.0, 0.0], /normal, Color=self.misc.palette.slate

			;\\ If in auto mode, only give frame to active object (and vidshows), else tell all registered plug-ins
			;\\ about the new frame and pass it to them

			struc = self.manager -> generate_list()

			vids = where(strlowcase(struc.type) eq 'vidshow', nvids)

			if self.runtime.mode eq 'auto' then begin

				now_time = dt_tm_tojs(systime())
				snapshot_lag_hours = (now_time - self.misc.snapshot_time)/3600.

				if nvids gt 0 then begin
					for n = 0, nvids - 1 do struc.ref(vids(n)) -> frame_event, image, channel
				endif

				if obj_valid(self.misc.active_object) then begin
					self.misc.active_object -> frame_event, image, channel
				endif else begin
					;\\ No active object, check schedule file for insructions
					self -> execute_schedule
			 	endelse

			endif else begin

				num = self.manager -> count_objects()

				if num gt 0 then begin
					for x = 0, num - 1 do begin
						if struc.need_frame(x) eq 1 then begin
							struc.ref(x) -> frame_event, image, channel
						endif
					endfor
				endif

			endelse


		endif

		;\\ Mode 1 acquisition needs to be started after the legs have been updated
		if self.camera.acquisition_mode eq 1 then res = call_external(self.misc.dll_name, 'uStartAcquisition')


; ##	endif else begin


; ##	endelse


TIMER_EVENT_END:
end

;\D\<Plugins which are running in auto-mode can call this method to indicate that they have>
;\D\<finished their current task, and another plugin can be made active. Plugins that don't>
;\D\<stick around (like the phasemapper) can also indicate that they should be destroyed.>
;\D\<stepsperorder plugins.>
pro XDIConsole::end_auto_object, id, $          ;\A\<Widget id>
                                 ref, $         ;\A\<Ovject reference>
                                 kill=kill      ;\A\<Destroy the plugin>

	if ref eq self.misc.active_object then begin
		self.misc.active_object = obj_new()

		if keyword_set(kill) then begin
			self -> Kill_Handler, id, /kill_widget
		endif

	endif

end

;\D\<The implementation of schedule file commands are placed in this function. If new schedule>
;\D\<commands are added, their actions should be placed in this method.>
pro XDIConsole::execute_schedule

	schedule_file = self.runtime.schedule
	schedule_line = self.misc.schedule_line
	lat = self.header.latitude
	lon = self.header.longitude
	wait, 0.05

	;\\ Check for phasemap, nm/step and snapshot refresh \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

		now_time = dt_tm_tojs(systime())

		phase_lag_hours = (now_time - self.etalon.phasemap_time)/3600.
		nm_step_lag_hours = (now_time - self.etalon.nm_per_step_time)/3600.

		schedule_file = self.runtime.schedule

		if nm_step_lag_hours gt 1000.*self.etalon.nm_per_step_refresh_hours then begin
			self->log, 'NM/Step lag is: ' + string(nm_step_lag_hours,f='(f0.1)') + ', refreshing...', 'Console', /display
			schedule_reader, schedule_file, 0, command, args, lat, lon, self, /refresh_nm_per_step
			if command eq 'eof' then begin
				self->log, 'No Stepsperorder command found in schedule file for refresh', 'Console', /display
				self.etalon.nm_per_step_time = now_time
			endif else begin
				self -> start_plugin, command, args=args, new_obj=new_obj
				if obj_valid(new_obj) then begin
					self.misc.active_object = new_obj
					res = new_obj -> auto_start(args)
				endif
			endelse
			goto, END_EXECUTE_SCHEDULE
		endif

		if phase_lag_hours gt self.etalon.phasemap_refresh_hours then begin
			self->log, 'Phasemap lag is: ' + string(phase_lag_hours,f='(f0.1)') + ', refreshing...', 'Console', /display
			schedule_reader, schedule_file, 0, command, args, lat, lon, self, /refresh_phasemap
			if command eq 'eof' then begin
				self->log, 'No Phasemapper command found in schedule file for refresh', 'Console', /display
				self.etalon.phasemap_time = now_time
			endif else begin
				self -> start_plugin, command, args=args, new_obj=new_obj
				if obj_valid(new_obj) then begin
					self.misc.active_object = new_obj
					res = new_obj -> auto_start(args)
				endif
			endelse
			goto, END_EXECUTE_SCHEDULE
		endif


	;\\ End of refresh check \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

	schedule_reader, schedule_file, schedule_line, command, args, lat, lon, self

	self.misc.schedule_line = schedule_line

	if command ne 'control' and command ne 'eof' then begin

		;\\ Steps/Order and Phasemapper plugins are started and destroyed as needed
			if command eq 'stepsperorder' or command eq 'phasemapper' then begin
				self->log, 'Schedule -> ' + command, 'Console', /display
				self -> cam_shutteropen, 0
				self -> start_plugin, command, args=args, new_obj=new_obj
				if obj_valid(new_obj) then begin
					self.misc.active_object = new_obj
					res = new_obj -> auto_start(args)
				endif
			endif


		;\\ Spectrum plugins are started at initialization, and switched to as needed
			if command eq 'spectrum' then begin

				self->log, 'Schedule -> Spectrum', 'Console', /display
				self -> cam_shutteropen, 0

				struc = self.manager -> generate_list()
				name = 'spectrum' + ' ' + args(0) + ' ' + args(2)
				spex_plugins = where(struc.type eq name, nspex)

				if nspex eq 0 then begin
					;\\ Plugin not opened for some reason, so create one and make it active
						self -> start_plugin, command, args=args, new_obj=new_obj
						if obj_valid(new_obj) then self.misc.active_object = new_obj
				endif else begin
					;\\ Plugin exists, make it active
						new_obj = struc.ref(spex_plugins(0))
						if obj_valid(new_obj) then self.misc.active_object = new_obj
				endelse

				;\\ Start the plugin running
					res = new_obj -> auto_start(args)

			endif


		;\\ ShutterClose command for closing shutter at end of night
			if command eq 'shutterclose' then begin
				self -> cam_shutterclose, 0
			endif

		;\\ ShutterOpen command for opening shutter (just in case....)
			if command eq 'shutteropen' then begin
				self -> cam_shutteropen, 0
			endif

		;\\ Shutdown command for spex plugins
			if command eq 'shutdownspex' then begin
				struc = self.manager -> generate_list()
				name = 'spectrum'
				spex_plugins = where(strlowcase(strmid(struc.type,0,8)) eq name, nspex)
				if nspex gt 0 then begin
					for s = 0, nspex - 1 do begin
						self -> Kill_Handler, struc.id(spex_plugins(s)), /kill_widget
						self->log, 'Shut down spex: ' + struc.type(spex_plugins(s)), 'Console', /display
					endfor
				endif
				;\\ Clear the SNR/SCAN value, ready for next obs
				self.runtime.snr_per_scan = 0.
			endif

		;\\ Camera settings command
			if command eq 'cameraset' then begin
				self -> cam_exptime, 0, new_time = float(args(0))
				self -> cam_gain, 0, new_gain = fix(args(1))
				self -> log, 'Camera Exp. Time: ' + args[0] + ', Gain: ' + args[1], 'Console', /display
			endif

		;\\ IDL batch file runner
			if command eq 'runscript' then begin
				program = args(0)
				res = execute(program)
			endif

		;\\ Drive mirror motor commands
			if command eq 'mirror' then begin
				case args(0) of
					'home_sky':  self -> mot_home_sky, 0
					'home_cal':	 self -> mot_home_cal, 0
					'drive_sky': self -> mot_drive_sky, 0
					'drive_cal': self -> mot_drive_cal, 0
					else:
				endcase
				self -> log, 'Drove Mirror: ' + args[0], 'Console', /display
			endif

		;\\ Drive calibration switch motor commands

			if command eq 'cal_switch' then begin
				self -> mot_sel_cal, fix(args(0))
			endif


		;\\ Filter commands
			if command eq 'filter' then begin
				filter_number = fix(args(0))
				current_filter = self.misc.current_filter
				if current_filter ne filter_number then begin
					log_path = self.logging.log_directory
					call_procedure, self.header.instrument_name + '_filter', filter_number, $
																		 log_path = log_path, $
																		 self.misc, $
																		 self
					self.misc.current_filter = filter_number
					self -> save_current_settings
				endif
				self -> log, 'Selected Filter ' + string(filter_number, f='(i0)'), 'Console', /display
			endif

		;\\ Wait command
			if command eq 'wait' then begin
				wait, fix(args[0])
			endif

		;\\ Log command (mainly for debugging), writes to the log
			if command eq 'log' then begin
				log_string = args[0]
				self->log, log_string, 'Console', /display
			endif

		;\\ Set the current status string
			if command eq 'set_status' then begin
				self.runtime.current_status = args[0]
			endif

			self.runtime.last_schedule_command = command + ': ' + strjoin(args, ', ', /single)

	endif

	if command eq 'eof' then self.misc.schedule_line = 0


END_EXECUTE_SCHEDULE:
end

;\D\<This is called by Spectrum plugins if they detect that something has gone wrong with the laser.>
;\D\<It shuts down all Spectrum plugins. The calling plugin then restarts the SDI software.>
pro XDIConsole::shutdown_spex

	self->log, 'LOST LASER SIGNAL - SHUTDOWN_SPEX CALLED', 'Console', /display
	struc = self.manager -> generate_list()
	name = 'spectrum'
	spex_plugins = where(strlowcase(strmid(struc.type,0,8)) eq name, nspex)
	if nspex gt 0 then begin
		for s = 0, nspex - 1 do begin
			self -> Kill_Handler, struc.id(spex_plugins(s)), /kill_widget
			self->log, 'Shut down spex: ' + struc.type(spex_plugins(s)), 'Console', /display
		endfor
	endif

end

;\D\<When a user clicks on a plugin in the menu or a schedule command requires a plugin to be>
;\D\<created this method is called. It is responsible for creating the plugin/object, registering>
;\D\<it with the widget manager>
pro XDIConsole::start_plugin, event, $             ;\A\<Widget event (manual) or string (auto start)>
                              args=args, $         ;\A\<No Doc>
                              new_obj=new_obj      ;\A\<No Doc>

		if size(event, /type) eq 8 then begin
			auto_start = 0
			widget_control, get_uval = uval_struc, event.id
			widget_control, get_val = val, event.id
			uval = uval_struc.name
			w = 0.0
		endif else begin
			auto_start = 1
			val = event
			w = float(args(0))
		endelse

		self->log, 'Creating plugin: ' + val, 'Console', /display

		xbin = self.camera.xbin
		ybin = self.camera.ybin

		if auto_start eq 0 and strlowcase(val) eq 'spectrum' then begin
			while w eq 0.0 do begin
				w = inputBox(w, title = "Set Wavelength in Nanometres", group = self.misc.console_id)
			endwhile
		endif

		xpix = self.camera.xpix
		ypix = self.camera.ypix

			obj_data = {	manager:self.manager, $
					    	 leader:self.misc.console_id, $
							console:self, $
							recover:0, $
							  count:0, $
						 wavelength:w, $
							 nchann:self.etalon.number_of_channels, $
							palette:self.misc.palette, $
							 header:self.header, $
							   xdim:ceil(xpix/xbin), $
							   ydim:ceil(ypix/ybin)  }

		;\\ Check to see if saved settings exist, if so restore old settings
			if file_test(self.misc.default_settings_path + '\plugins\' + strlowcase(val) + '.sdi') then begin
				obj_data.recover = 1
			 	restore, self.misc.default_settings_path + '\plugins\' + strlowcase(val) + '.sdi', /relaxed
				restore_struc = save_struc
			endif else begin
				;\\ If not, create a new instance of that module
					obj_data.recover = 0
					restore_struc = 0
			endelse

			self.misc.object_count 	= self.misc.object_count + 1
			obj_data.count 			= self.misc.object_count

			if val eq 'spectrum' and auto_start eq 1 then begin
				new_inst = obj_new('SDI' + val, restore_struc = restore_struc, data = obj_data, zone_settings = args(1), $
									file_name_format=args(2))
			endif else begin
				new_inst = obj_new('SDI' + val, restore_struc = restore_struc, data = obj_data)
			endelse

			if obj_valid(new_inst) then begin
				if val eq 'spectrum' then val = val + ' ' + args(0) + ' ' + args(2)
				struc = new_inst -> get_settings()
				self.manager  -> register, struc.id, new_inst, val, 1, struc.need_timer, struc.need_frame
				xmanager, 'base', struc.id, event_handler = 'Handle_Event', cleanup = 'Kill_Entry', /no_block
			endif

			new_obj = new_inst

		;\\ Discard any images accumulated in the camera while the plugin was setting up:
			resx = call_external(self.misc.dll_name, 'uAbortAcquisition')
			resx = call_external(self.misc.dll_name, 'uFreeInternalMemory')
			resx = call_external(self.misc.dll_name, 'uStartAcquisition')
			template_image = *self.buffer.image
			*self.buffer.image = template_image - template_image
			self->log, 'Cleared stored images...', 'Console', /display
end

;\D\<Update the camera with the current set of values stored in the \verb"camera" structure of>
;\D\<the console settings. If you want to add new camera commands, do so here, and make sure to>
;\D\<include the new command anywhere that this function is called.>
pro XDIConsole::update_camera, commands, $   ;\A\<A string array of commands>
                               results       ;\A\<OUT: a string array of results from the commands>

	camera = self.camera

	results = strarr(n_elements(commands))
	xbin = fix(camera.xbin)
	ybin = fix(camera.ybin)

	status = 0
	restart_acq = 0
	res = call_external(self.misc.dll_name, 'uGetStatus', status)
	res = call_external(self.misc.dll_name, 'uAbortAcquisition')

	for x = 0, n_elements(commands) - 1 do begin

		case commands(x) of

		'uGetPixels':begin
			xpix = 0
			ypix = 0
			results(x) = get_error(call_external(self.misc.dll_name, 'uGetDetector', xpix, ypix))
			self->log, 'Read camera pixels - ' + string(xpix, f='(i0)')  + 'x' + string(ypix, f='(i0)'), 'Console', /display
			self.camera.xpix = xpix
			self.camera.ypix = ypix
		end

		'uSetReadMode': begin
			;\\ Set read mode
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetReadMode', camera.read_mode))
			self->log, 'Read mode - ' + string(camera.read_mode, f='(i0)')  + ': ' + results(x), 'Console', /display
		end

		'uSetImage': begin
			;\\ Set Image mode attributes: binning, size of image
			xpix = self.camera.xpix
			ypix = self.camera.ypix
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetImage', long(xbin), long(ybin), long(1), long(xpix), long(1), long(ypix)))
			self->log, 'Image size - 512x512, binning - ' + string(xbin,f='(i0)') + $
								' x ' + string(ybin,f='(i0)') + ' : ' + results(x), 'Console', /display
		end

		'uSetAcquisitionMode': begin
			;\\ Set acquisition mode
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetAcquisitionMode', long(camera.acquisition_mode)))
			self->log, 'Acquisition mode - ' + string(camera.acquisition_mode, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetFrameTransferMode': begin
			;\\ Set frame transfer mode
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetFrameTransferMode', 1L))
			self->log, 'Frame transfer - 1' +  ': ' + results(x), 'Console', /display
		end

		'uSetBaselineClamp': begin
			;\\ Set baseline clamping on
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetBaselineClamp', long(camera.baseline_clamp)))
			self->log, 'Baseline Clamp - ' + string(camera.baseline_clamp, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetPreAmpGain': begin
			;\\ Set baseline clamping on
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetPreAmpGain', long(camera.preamp_gain)))
			self->log, 'Preamp Gain - ' + string(camera.preamp_gain, f='(i0)') +  ': ' + results(x), 'Console', /display
		end

		'uSetEMGainMode': begin
			;\\ Set Extended EM gain Mode:
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetEMAdvanced', 1L))
			self->log, 'EM Advanced Gain Access - 1' +  ': ' + results(x), 'Console', /display
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetEMGainMode', long(camera.em_gain_mode)))
			self->log, 'EM Gain Mode - ' + string(camera.em_gain_mode, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetVSAmplitude': begin
			;\\ Set Amplitude of the vertical shift clock pulse:
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetVSAmplitude', long(camera.vs_amplitude)))
			self->log, 'Vertical Shift Pulse Amplitude - ' + string(camera.vs_amplitude, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetADChannel': begin
			;\\ Amp 0 is high sped 14 bit, amp 1 is only 1MHz 16 bit.
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetADChannel', long(camera.ad_channel)))
			self->log, 'AD Channel - ' + string(camera.ad_channel, f='(i0)') + ': ' + results(x), 'Console', /display
		end

        'uSetOutputAmplifier': begin
			;\\ Amp 0 is EM mode, Amp 1 is regular
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetOutputAmplifier', long(camera.output_amplifier)))
			self->log, 'Output Amp - ' + string(camera.output_amplifier, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetTriggerMode': begin
			;\\ Set internal triggering
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetTriggerMode', camera.trigger_mode))
			self->log, 'Triggering - ' + string(camera.trigger_mode, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uSetHSSpeed': begin
			;\\ Set horizontal shift speed (2 is slowest HS speed, 0 is fastest)
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetHSSpeed', long(0), long(camera.hs_speed)))
			self->log, 'HS Speed - ' + string(camera.hs_speed, f='(i0)') + ':' + results(x), 'Console', /display
		end

		'uSetVSSpeed': begin
			;\\ Set vertical shift speed
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetVSSpeed', long(camera.vert_shift_speed)))
			speed = 0.0
			res = call_external(self.misc.dll_name, 'uGetVSSpeed', camera.vert_shift_speed, speed)
			self->log, 'VS Speed - ' + string(speed, f='(f0.3)') + ': ' + results(x), 'Console', /display
		end

		'uSetShutter': begin

			;\\ Set shutter to full open, opening time 10 ms, closing time 0 ms
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetShutter', 1, long(camera.shutter_mode), long(camera.shutter_closing_time), long(camera.shutter_opening_time)))
			self->log, 'Shutter: ', 'Console', /display
			self->log, 'Type - '+ string(1, f='(i0)') + ', Mode - ' + string(camera.shutter_mode, f='(i0)') + $
							', Close time - ' + string(camera.shutter_closing_time, f='(i0)') + ', Open time - '+ string(camera.shutter_opening_time, f='(i0)'), 'Console', /display
			if camera.shutter_mode eq 1 then self.runtime.shutter_state = 1
			if camera.shutter_mode eq 2 then self.runtime.shutter_state = 0
		end

		'uSetExposureTime': begin
			;\\ Set exposure time
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetExposureTime', camera.exposure_time))
;			MC: Added the following line, which might be helpful for acquisition mode 5:
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetKineticCycleTime', camera.exposure_time+0.01))
			self->log, 'Exposure time - ' + string(camera.exposure_time, f='(f0.3)') + ': ' + results(x), 'Console', /display
		end

		'uSetTemperature': begin
			;\\ Set cooler temperature
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetTemperature', long(camera.cooler_temp)))
			self->log, 'Cooler Temp - ' + string(camera.cooler_temp, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		'uCoolerON': begin
			;\\ Turn on the cooler
			results(x) = get_error(call_external(self.misc.dll_name, 'uCoolerON'))
			self->log, 'Cooler is ON - ' + results(x), 'Console', /display
		end

		'uCoolerOFF': begin
			;\\ Turn off the cooler
			results(x) = get_error(call_external(self.misc.dll_name, 'uCoolerOFF'))
			self->log, 'Cooler is OFF - ' + results(x), 'Console', /display
		end

		'uGetTemperatureRange': begin
			min_temp = 0
			max_temp = 0
			res = call_external(self.misc.dll_name, 'uGetTemperatureRange', min_temp, max_temp)
			self.camera.cam_min_temp = min_temp
			self.camera.cam_max_temp = max_temp
		end

		'uSetGain': begin
			;\\ Turn off the cooler
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetEMCCDGain', long(self.camera.gain)))
			self->log, 'Gain: ' + string(self.camera.gain,f='(i0)') + ' - ' + results(x), 'Console', /display
		end

		'uSetFanMode': begin
			;\\ Set fan mode
			results(x) = get_error(call_external(self.misc.dll_name, 'uSetFanMode', long(camera.fan_mode)))
			self->log, 'Fan mode - ' + string(camera.fan_mode, f='(i0)') + ': ' + results(x), 'Console', /display
		end

		else: begin
			results(x) = 'Unknown Command'
		end

		endcase

	endfor

	res = get_error(call_external(self.misc.dll_name, 'uSetHighCapacity', 0L))
	self->log, 'unSet High Capacity - ' + res, 'Console', /display


	res = call_external(self.misc.dll_name, 'uStartAcquisition')
	self->log, 'Settings updated, restarting acquisition: ' + get_error(res), 'Console', /display

end

;\D\<Plugins can use this method to take captures of their draw widgets and have them saved to>
;\D\<the \verb"screen_capture_path" field of the \verb"misc" structure in the console settings.>
;\D\<Images can be saved as jpeg or png. The widget using this function needs to define a uval>
;\D\<structure with the following with the following fields: tag:"image\_capture", type:"jpg" >
;\D\<or "png", id:[array of tv ids], name:[array of string names, same size as id array].>
;\D\<Events from widgets with a uval.tag of "image\_capture" will always be routed to here,>
;\D\<instead of to the plugin as would usually occur.>
pro XDIConsole::image_capture, event  ;\A\<Widget event>

	widget_control, get_uval = struc, event.id

	time = systime(/julian)
	js_time = jd2js(time)
	weekday = js2weekday(js_time, /name)
	js2ymds, js_time, year, month, day, seconds
	hour = (seconds / 3600.)
	mins = (hour mod 1) * 60
	secs = (mins mod 1) * 60
	hour = hour - ((seconds / 3600.) mod 1)

	stamp = ' ' + weekday + ' ' + string(day, f='(i0)')  + '-' + string(month, f='(i0)')
	stamp = stamp + '-' + string(year, f='(i0)') + ' @ ' + string(hour, f='(i0)')
	stamp = stamp + '-' + string(mins, f='(i0)') + '-' + string(secs, f='(i0)')

	for x = 0, n_elements(struc.id) - 1 do begin
		widget_control, get_value = tv_id, struc.id(x)
		wset, tv_id
		image = tvrd(/true)
		if not file_test(self.misc.screen_capture_path, /directory) then file_mkdir, self.misc.screen_capture_path
		if struc.type eq 'png' then write_png, self.misc.screen_capture_path + struc.name(x) + stamp + '.png', image
		if struc.type eq 'jpg' then write_jpeg, self.misc.screen_capture_path + struc.name(x) + stamp + '.jpg', image, /true
	endfor

end

;\D\<Reload the current settings file.>
pro XDIConsole::reload_settings, event				;\A\<Widget event>
	self->load_settings, filename = self.runtime.settings
end

;\D\<Load all settings (same as on startup)>
pro XDIConsole::load_settings_full, event				;\A\<Widget event>
	self->load_settings, event, /first_call
end

;\D\<A new implementation of the settings file loader, testing.>
pro XDIConsole::load_settings, event, $				;\A\<Widget event>
							   filename=filename, $    ;\A\<Filename to load from>
							   error=error, $          ;\A\<OUT: error code>
                               first_call=first_call   ;\A\<Set if this is the first time settings are being loaded (i.e. in init)>

	error = 0

	temp = {etalon:self.etalon, $
			camera:self.camera, $
			header:self.header, $
			logging:self.logging, $
			misc:self.misc}

	if not keyword_set(filename) then begin
		filename = dialog_pickfile(path = self.misc.default_settings_path)
		self.runtime.settings = filename
	endif

	if filename ne '__no_settings_file_provided__' then begin
		name = (strsplit(file_basename(filename), '.', /extract))[0]
		resolve_routine, name
		call_procedure, name, temp
	endif

	self.etalon 	= temp.etalon
	self.camera 	= temp.camera
	self.header 	= temp.header
	self.logging 	= temp.logging
	self.misc 		= temp.misc

	xpix = self.camera.xpix
	ypix = self.camera.ypix

	x_dimension = ceil(xpix/float(self.camera.xbin))
	y_dimension = ceil(ypix/float(self.camera.ybin))

	ptr_free, self.buffer.image, $
			  self.buffer.raw_image, $
			  self.etalon.phasemap_base, $
			  self.etalon.phasemap_grad

	self.etalon.phasemap_base = ptr_new(intarr(x_dimension, y_dimension))
	self.etalon.phasemap_grad = ptr_new(intarr(x_dimension, y_dimension))
	self.buffer.image = ptr_new(ulonarr(x_dimension, y_dimension))
	self.buffer.raw_image = ptr_new(ulonarr(x_dimension, y_dimension))

	if file_test(self.misc.default_settings_path + 'persistent.idlsave') then begin

		;\\ In case loading the persistent file fails (corrupted), just skip it
		catch, error_status
		if error_status ne 0 then begin
			catch, /cancel
			goto, SKIP_PERSISTENT_LOAD
		endif

		restore, self.misc.default_settings_path + 'persistent.idlsave', /relaxed

		if size(persistent, /type) eq 8 then begin

			help, persistent, /str

			;\\ Only load these on init (or when 'Load Settings (full restore)' is selected)
			if keyword_set(first_call) then begin
				self.etalon.leg1_voltage = persistent.etalon.leg1_voltage
				self.etalon.leg2_voltage = persistent.etalon.leg2_voltage
				self.etalon.leg3_voltage = persistent.etalon.leg3_voltage
				self.misc.motor_cur_pos  = persistent.misc.motor_cur_pos
				self.misc.current_filter = persistent.misc.current_filter
				self.misc.current_source = persistent.misc.current_source
			endif

			;\\ Always load the phasemap and nm/step times
			self.etalon.phasemap_lambda = persistent.etalon.phasemap_lambda
			self.etalon.phasemap_time = persistent.etalon.phasemap_time
			self.etalon.nm_per_step_time = persistent.etalon.nm_per_step_time

			;\\ Make sure dimensions match
			dims = size(persistent.etalon.phasemap_base, /dimensions)
			if dims[0] eq x_dimension and $
			   dims[1] eq y_dimension then *self.etalon.phasemap_base = persistent.etalon.phasemap_base

			dims = size(persistent.etalon.phasemap_grad, /dimensions)
			if dims[0] eq x_dimension and $
			   dims[1] eq y_dimension then *self.etalon.phasemap_grad = persistent.etalon.phasemap_grad

		endif ;\\ if persistent valid

	endif ;\\ if persistent exists
	SKIP_PERSISTENT_LOAD:


	;\\ Update the camera
		commands = ['uSetShutter', 'uSetReadMode', 'uSetImage', 'uSetAcquisitionMode', $
					'uSetFrameTransferMode', 'uSetPreAmpGain', 'uSetEMGainMode', 'uSetVSAmplitude', $
					'uSetBaselineClamp', 'uSetADChannel', 'uSetOutputAmplifier', 'uSetTriggerMode', 'uSetHSSpeed', $
					'uSetVSSpeed', 'uSetExposureTime', 'uSetTemperature', 'uGetTemperatureRange', 'uSetGain', 'uSetFanMode']

		if self.camera.cooler_on eq 1 then commands = [commands, 'uCoolerON'] else commands = [commands, 'uCoolerOFF']
		if not keyword_set(first_call) then self -> update_camera, commands, results

	;\\ Show gain and exp times and shutter state
		if self.runtime.shutter_state eq 0 then shutter_string = 'CLOSED' else shutter_string = 'OPEN'
		exp_time_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_exp_time_guage')
		gain_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_gain_guage')
		shutter_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_shutter_guage')
		motor_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
		widget_control, set_value = 'Exp Time: ' + string(self.camera.exposure_time, f='(f0.3)') + ' s', exp_time_guage_id
		widget_control, set_value = 'Gain: ' + string(self.camera.gain, f='(i0)'), gain_guage_id
		widget_control, set_value = 'Shutter: ' + shutter_string, shutter_guage_id
		widget_control, set_value = 'MotorPos: ' + string(self.misc.motor_cur_pos,f='(i0)'), motor_guage_id
end

;\D\<Write settings to a file.>
pro XDIConsole::write_settings, event, $ ;\A\<Widget event>
								filename=filename, $ ;\A\<Write the settings file to this filename>
								pfilename=pfilename  ;\A\<Write the persistent file to this filename>

	if self.runtime.settings eq '__no_settings_file_provided__' then return

	fname = self.runtime.settings
	proname = (strsplit(file_basename(fname), '.', /extract))[0]
	info = routine_info(proname, /source)

	tab = string(9B)
	newline = string([13B,10B])

	outname = info.path
	if keyword_set(filename) then outname = filename

	openw, hnd, outname, /get
	printf, hnd, 'pro ' + info.name + ', data'
	printf, hnd, newline + tab + ';\\ ETALON'
	printf, hnd, self->write_settings_struc('etalon', self.etalon, tab)
	printf, hnd, newline + tab + ';\\ CAMERA'
	printf, hnd, self->write_settings_struc('camera', self.camera, tab)
	printf, hnd, newline + tab + ';\\ HEADER'
	printf, hnd, self->write_settings_struc('header', self.header, tab)
	printf, hnd, newline + tab + ';\\ LOGGING'
	printf, hnd, self->write_settings_struc('logging', self.logging, tab)
	printf, hnd, newline + tab + ';\\ MISC'
	printf, hnd, self->write_settings_struc('misc', self.misc, tab)
	printf, hnd, 'end'
	close, hnd
	free_lun, hnd

	outname = self.misc.default_settings_path + 'persistent.idlsave'
	if keyword_set(pfilename) then outname = pfilename

	persistent =  {$

				   etalon:{phasemap_base:*self.etalon.phasemap_base, $
				   		   phasemap_grad:*self.etalon.phasemap_grad, $
				   		   phasemap_time:self.etalon.phasemap_time, $
				   		   nm_per_step_time:self.etalon.nm_per_step_time, $
				   		   phasemap_lambda:self.etalon.phasemap_lambda, $
				   		   leg1_voltage:self.etalon.leg1_voltage, $
				   		   leg2_voltage:self.etalon.leg2_voltage, $
				   		   leg3_voltage:self.etalon.leg3_voltage }, $

				   misc:{motor_cur_pos:self.misc.motor_cur_pos, $
				   		 current_filter:self.misc.current_filter, $
				   		 current_source:self.misc.current_source} $

				   }

	save, filename = outname, persistent

end

;\D\<Return a string version of a struc for the settings file (internal use).>
function XDIConsole::write_settings_struc, name, $ ;\A\<Name of the structure>
										   struc, $ ;\A\<The actual structure>
										   indent, $ ;\A\<Indentation level>
										   show_all=show_all ;\A\<Show non-editable fields too>
	str = ''
	names = tag_names(struc)
	edits = where(names eq 'EDITABLE', edits_yn)
	for i = 0, n_tags(struc) - 1 do begin
		if edits_yn eq 1 then match = where(strupcase(struc.editable) eq names[i], can_edit) $
			else can_edit = 1
		if (can_edit eq 1) or keyword_set(show_all) then $
			str += self->write_settings_field(name + '.' + names[i], $
				   struc.(i), indent, show_all=show_all) + string([13B,10B])
	endfor
	return, str
end

;\D\<Return a string version of a field for the settings file (internal use).>
function XDIConsole::write_settings_field, name, $ ;\A\<Name of the field>
										   field, $ ;\A\<The actual field>
										   indent, $ ;\A\<Indentation level>
										   show_all=show_all ;\A\<Show non-editable fields too>
	if size(field, /type) eq 8 then begin
		return, self->write_settings_struc(name, field, indent, show_all=show_all)
	endif else begin
		is_string = 0
		case size(field, /type) of
			1: fmt = '(i0)'
			2: fmt = '(i0)'
			3: fmt = '(i0)'
			4: fmt = '(f0)'
			7: is_string = 1
			else: return, indent + 'data.' + name + ' = ' + size(field, /tname)
		endcase
		if is_string eq 0 then field_string = string(field, f=fmt) else field_string = "'" + field + "'"
		if n_elements(field_string) gt 1 then begin
			pre_spaces = strjoin(replicate(' ', strlen(indent + 'data.' + name) + 4), '', /single)
			out_string = '[' + strjoin(field_string, ',' + string([13B,10B]) + pre_spaces, /single) + ']'
		endif else begin
			out_string = field_string
		endelse
		return, indent + 'data.' + name + " = " + out_string
	endelse
end


;\D\<Save current settings file, forwards to write_settings.>
pro XDIConsole::save_current_settings, filename=filename, $ ;\A\<Settings filename to save to>
									   pfilename=pfilename  ;\A\<Persistent-data filename to save to>
	self->write_settings, filename=filename, pfilename=pfilename
end

;\D\<Show the current settings file (shows all fields).>
pro XDIConsole::show_current_settings, event ;\A\<Widget event>

	tab = string(9B)
	newline = string([13B,10B])
	text = ''
	text += newline + strupcase(self.runtime.settings) + newline
	text += newline + '>> ETALON' + newline
	text += self->write_settings_struc('etalon', self.etalon, '', /show_all)
	text += newline + '>> CAMERA' + newline
	text += self->write_settings_struc('camera', self.camera, '', /show_all)
	text += newline + '>> HEADER' + newline
	text += self->write_settings_struc('header', self.header, '', /show_all)
	text += newline + '>> LOGGING' + newline
	text += self->write_settings_struc('logging', self.logging, '', /show_all)
	text += newline + '>> MISC' + newline
	text += self->write_settings_struc('misc', self.misc, '', /show_all)

	base = widget_base(group_leader = self.misc.console_id, col = 1)
	text = widget_text(base, value = text, font = 'Courier*15', $
					   ys = 50, xs = 100., /scroll)
	widget_control, /realize, base
end


;\D\<Called by widgets when they want to log events. These get logged to a log file,>
;\D\<and optionally output to the display.>
pro XDIConsole::log, entry, $                         ;\A\<String containing the log message>
                     sender, $                        ;\A\<String identifying the sender of the message>
                     display_entry=display_entry      ;\A\<Set this if the message is to be displayed to the console log window>

;		logging = {log,    log_directory:'', $
;				    time_name_format:'', $
;				      enable_logging:0, $
;				       log_overwrite:0, $
;				          log_append:0, $
;				        ftp_snapshot:'', $
;				        		 log:strarr(100), $
;				         log_entries:0, $
;				    	    editable:[0,1,2,3,4,5]}

	;\\ Set up an error handler. Failing to log should not cause a crash.
	error_retries = 0 ;\\ try 3 times to log, else give up
	catch, error
	if error ne 0 then begin
		if error_retries ge 3 then begin
			catch, /cancel
			return
		endif else begin
			error_retries++
			wait, 5
		endelse
	endif

	if self.logging.enable_logging ne 0 and size(sender, /type) ne 0 then begin

		time = convert_js(dt_tm_tojs(systime(/ut)))
		path = self.logging.log_directory + '\' + ymd2string( time.year, time.month, time.day, separator='_')
		file_mkdir, path

		log_filename = strlowcase(strcompress(sender, /remove))

		openw, handle, path + '\' + log_filename + '_log.txt', /get_lun, /append
		printf, handle, strmid(systime(/ut),10,9) + ' >> ' + entry
		free_lun, handle
	endif


	if keyword_set(display_entry) then begin

		if widget_info(self.misc.log_id, /valid_id) eq 1 then begin

			count = self.logging.log_entries
			if count eq 99 then begin
				self.logging.log = shift(self.logging.log, -50)
				self.logging.log[49] = strmid(systime(/ut),10,9) + ' >> ' + entry
				self.logging.log[50:*] = ''
				self.logging.log_entries = 50
			endif else begin
				self.logging.log[count] = strmid(systime(/ut),10,9) + ' >> ' + entry
				self.logging.log_entries ++
			endelse

			widget_control, set_value = self.logging.log, self.misc.log_id
			widget_control, set_text_top_line = count - 10, self.misc.log_id

		endif

	endif

end

;\D\<This is called when the user toggles between auto and manual mode from the console menu.>
pro XDIConsole::mode_switch, event  ;\A\<Widget event>

	id = widget_info(self.misc.console_id, find_by_uname = 'Console_mode_switch')

	if self.runtime.mode eq 'manual' then begin

		;\\ Switching to AUTO MODE

		if self.runtime.schedule eq '' then begin
			mess = ['Schedule file required for automatic operation.','Select a file?']
			res = dialog_message(mess, /question)
			if res eq 'Yes' then begin
				fname = dialog_pickfile(path = self.misc.default_settings_path)

				;\\ TODO: Check for valid schedule file
				self.misc.schedule_line = 0
				self.runtime.mode = 'auto'
				widget_control, id, set_value = 'Switch to Manual Mode'
				title = 'SDI CONSOLE - ' + self.header.instrument_name + ' - Mode: ' + self.runtime.mode
				widget_control, self.misc.console_id, base_set_title = title

			endif else begin
				goto, END_MODE_SWITCH
			endelse
		endif else begin
			self.misc.schedule_line = 0
			self.runtime.mode = 'auto'
			widget_control, id, set_value = 'Switch to Manual Mode'
			title = 'SDI CONSOLE - ' + self.header.instrument_name + ' - Mode: ' + self.runtime.mode
			widget_control, self.misc.console_id, base_set_title = title
		endelse

	endif else begin

		;\\ Switching to MANUAL MODE

		self.runtime.mode = 'manual'
		widget_control, id, set_value = 'Switch to Auto Mode'
		widget_control, self.misc.console_id, base_set_title = 'SDI CONSOLE -- Mode: ' + self.runtime.mode

	endelse


END_MODE_SWITCH:
end

;\D\<Called to retrieve the current camera temperature. In normal camera running mode (run till abort)>
;\D\<this will not retrieve the temperature unless the calling widget sets a field called \verb"force">
;\D\<equal to 1, which forces an abort acquisition.>
pro XDIConsole::cam_temp, event  ;\A\<Widget event>

	widget_control, get_uval = uval, event.id

	if uval.force eq 1 then begin
		res = call_external(self.misc.dll_name, 'uAbortAcquisition')
		temp = 0.0;
		res = call_external(self.misc.dll_name, 'uGetTemperatureF', temp, val=[0b])
		self.camera.cam_temp = temp
		self.camera.temp_state = get_error(res)
		res = call_external(self.misc.dll_name, 'uStartAcquisition')
	endif

	temp = self.camera.cam_temp
	self->log, 'Camera Temperature is: ' + string(temp, format = '(f0)'), 'Console', /display
	self->log, 'Temperature State is: '  + self.camera.temp_state, 'Console', /display
end

;\D\<Retrieve the current camera status.>
pro XDIConsole::cam_status, event  ;\A\<Widget event>

	status = 0
	res = get_error(call_external(self.misc.dll_name, 'uGetStatus', status))
	if res eq 'DRV_SUCCESS' then begin
		self->log, 'Camera Status: ' + get_error(status), 'Console', /display
	endif else begin
		self->log, 'Camera Status: ' + res, 'Console', /display
	endelse

end

;\D\<Called when the user clicks on the Cooler menu option. Opens up a widget for controlling camera>
;\D\<temperature set point.>
pro XDIConsole::cam_cooler, event  ;\A\<Widget event>

	res = ''

	if self.runtime.mode eq 'auto' then begin
		mess = ['Warning: Console is running automatically! Changing cooler settings',$
			   'could have adverse effects. Do you want to continue?']
		res = dialog_message(mess, /question)
	endif

	if res eq 'Yes' or self.runtime.mode eq 'manual' then begin

		set_temp = self.camera.cooler_temp
		cam_temp = self.camera.cam_temp
		cool = self.camera.cooler_on
		minim = self.camera.cam_min_temp
		maxim = self.camera.cam_max_temp

		if cool eq 1 then state_val = 'Turn Cooler OFF' else state_val = 'Turn Cooler ON'
		if cool eq 1 then cool_val = 'ON' else cool_val = 'OFF'

		geom = widget_info(self.misc.console_id, /geometry)
		xoff = geom.xoffset + 20
		yoff = geom.yoffset + 20

		font = 'Ariel*15*Bold'

		base = widget_base(group_leader = self.misc.console_id, xs = 300, ys = 250, xoff=xoff, yoff=yoff, title='Cooling')

		warning1 = widget_label(base, xoff=10, yoff=10, value = 'IF SET POINT IS CHANGED WHEN COOLER IS', font=font)
		warning2 = widget_label(base, xoff=10, yoff=30, value = 'ON, COOLER WILL BE RESTARTED', font=font)

		on_off_but = widget_button(base, xoff = 10, yoff = 190, value = state_val, uname='Console_'+self.obj_num+'coolerbut', $
								   uvalue = {tag:'cam_cooler_event', event:'toggle'}, font=font)
		update_but = widget_button(base, xoff = 140, yoff = 190, value = 'Update Set Point', uname='Console_'+self.obj_num+'setbut', $
								   uvalue = {tag:'cam_cooler_event', event:'set'}, font=font)
		curr_cool = widget_label(base, xoff=10, yoff=70, value = 'Cooler is currently ' + cool_val, $
								uname='Console_'+self.obj_num+'coolerval', font=font)

		current = widget_label(base, xoff = 10, yoff = 100, value = 'Current Temperature: ' + string(cam_temp,f='(f0.2)'), $
							  uname='Console_'+self.obj_num+'camtemp', font=font)
		set_label = widget_label(base, xoff = 10, yoff = 130, value = 'Set Temperature:', font=font)
		set_box	= widget_slider(base, xoff = 100, yoff = 130, value = set_temp, minim=minim, maxim=maxim, $
						     uname='Console_'+self.obj_num+'settemp', uval = {tag:'cam_cooler_event', event:'slider'}, font=font)

		self.manager -> register, base, self, 'Console internal', 0, 0, 0
		widget_control, base, /realize
		xmanager, 'base', base, event_handler = 'Handle_Event', cleanup = 'Kill_Entry', /no_block

	endif
end

;\D\<Event handler for the camera cooler widget.>
pro XDIConsole::cam_cooler_event, event  ;\A\<Widget event>

	cool = self.camera.cooler_on

	status = 0
	res = call_external(self.misc.dll_name, 'uGetStatus', status)
	restart_acq = 0

	if get_error(status) eq 'DRV_ACQUIRING' then begin
		res = call_external(self.misc.dll_name, 'uAbortAcquisition')
		restart_acq = 1
	endif

	widget_control, event.id, get_uval = uval

	if uval.event eq 'toggle' then begin
		coolerval_id = widget_info(event.top, find_by_uname='Console_'+self.obj_num+'coolerval')
		if cool eq 1 then begin
			res = call_external(self.misc.dll_name, 'uCoolerOFF')
			self->log, 'Turned Cooler OFF - ' + get_error(res), 'Console', /display
			if get_error(res) eq 'DRV_SUCCESS' then begin
				self.camera.cooler_on = 0
				cool = 0
				widget_control, set_value = 'Cooler is current OFF', coolerval_id
			endif
		endif else begin
			res = call_external(self.misc.dll_name, 'uCoolerON')
			self->log, 'Turned Cooler ON - ' + get_error(res), 'Console', /display
			if get_error(res) eq 'DRV_SUCCESS' then begin
				self.camera.cooler_on = 1
				cool = 1
				widget_control, set_value = 'Cooler is currently ON', coolerval_id
			endif
		endelse

		if cool eq 1 then state_val = 'Turn Cooler OFF' else state_val = 'Turn Cooler ON'
		widget_control, set_value = state_val, event.id

	endif

	if uval.event eq 'set' then begin
		slider_id = widget_info(event.top, find_by_uname='Console_'+self.obj_num+'settemp')
		widget_control, get_value = slider_val, slider_id
		self.camera.cooler_temp = slider_val
		if cool eq 1 then begin
			res = call_external(self.misc.dll_name, 'uCoolerOFF')
			self->log, 'Turned Cooler OFF - ' + get_error(res), 'Console', /display
			if get_error(res) eq 'DRV_SUCCESS' then begin
				res = call_external(self.misc.dll_name, 'uSetTemperature', long(self.camera.cooler_temp))
				res = call_external(self.misc.dll_name, 'uCoolerON')
				self->log, 'Turned Cooler ON - ' + get_error(res), 'Console', /display
				if get_error(res) ne 'DRV_SUCCESS' then self.log -> update, 'Failed to start cooler!'
			endif else begin
				self->log, 'Failed to stop cooler!', 'Console', /display
			endelse
		endif else begin
			self.camera.cooler_temp = slider_val
			res = call_external(self.misc.dll_name, 'uSetTemperature', long(self.camera.cooler_temp))
		endelse
	endif

	if restart_acq eq 1 then res = call_external(self.misc.dll_name, 'uStartAcquisition')

end

;\D\<Update the etalon legs (plate separation).>
pro XDIConsole::update_legs, leg1=leg1, $   ;\A\<Optional leg 1 value>
                             leg2=leg2, $   ;\A\<Optional leg 2 value>
                             leg3=leg3, $   ;\A\<Optional leg 3 value>
                             legs=legs      ;\A\<Update all legs using their current values>

	;print, 'Reached leg update 1:', systime()

	;\\ Update the legs
		if not keyword_set(legs) then begin
			self.etalon.leg1_voltage = self.etalon.leg1_base_voltage + self.etalon.start_volt_offset*self.etalon.leg1_offset + float(self.etalon.current_channel) * $
								   (self.etalon.leg1_offset*self.etalon.volt_step_size)

			self.etalon.leg2_voltage = self.etalon.leg2_base_voltage + self.etalon.start_volt_offset*self.etalon.leg2_offset + float(self.etalon.current_channel) * $
	    	                       (self.etalon.leg2_offset*self.etalon.volt_step_size)

			self.etalon.leg3_voltage = self.etalon.leg3_base_voltage + self.etalon.start_volt_offset*self.etalon.leg3_offset + float(self.etalon.current_channel) * $
	   	                        (self.etalon.leg3_offset*self.etalon.volt_step_size)
		endif else begin
			if keyword_set(leg1) then self.etalon.leg1_voltage = leg1
			if keyword_set(leg2) then self.etalon.leg2_voltage = leg2
			if keyword_set(leg3) then self.etalon.leg3_voltage = leg3
		endelse

	;\\ Check for upper voltage limit
		if self.etalon.leg1_voltage ge self.etalon.max_voltage $
		or self.etalon.leg2_voltage ge self.etalon.max_voltage $
		or self.etalon.leg3_voltage ge self.etalon.max_voltage then begin
			self -> scan_etalon, 'Console - leg limiter', /stop_scan
			if self.runtime.mode eq 'manual' then begin
				mess = 'Scan Stopped: Voltage has reached upper limit'
				res = dialog_message(mess)
				self->log, 'Scan Stopped: Voltage has reached upper limit', 'Console', /display
			endif else begin
				self->log, 'Scan Stopped: Voltage has reached upper limit', 'Console', /display
			endelse
			goto, END_SCAN_ETALON
		endif

			port = self.misc.port_map.etalon.number
			dll_name = self.misc.dll_name

			call_procedure, self.header.instrument_name + '_etalon', dll_name, $
																	 self.etalon.leg1_voltage, $
																	 self.etalon.leg2_voltage, $
																	 self.etalon.leg3_voltage, $
																	 self.misc, $
																	 self

END_SCAN_ETALON:
end

;\D\<Call the instrument-specific initialise routine.>
pro XDIConsole::file_re_initialize, event  ;\A\<Widget event>

	;\\ Call the instrument specific initialisation routine
		call_procedure, self.header.instrument_name + '_initialise', self.misc, self

end

;\D\<Print out a list (to the console log) of active plugins.>
pro XDIConsole::file_show, event  ;\A\<Widget event>

	num = (self.manager -> count_objects()) - 1
	struc = self.manager -> generate_list()

	self->log, 'Active Plugins: (' + string(num, f='(i0)') + ')', 'Console', /display
	for n = 0, num - 1 do begin
		self->log, '	' + string(n,f='(i0)') + '   ' + struc.type(n), 'Console', /display
	endfor

end

;\D\<Open up notepad to show the current schedule file if one is set.>
pro XDIConsole::file_show_sched, event  ;\A\<Widget event>

	if self.runtime.schedule ne '' then begin
		spawn, /noshell, /nowait, 'notepad ' + self.runtime.schedule
	endif

end

;\D\<Open up a dialog to select a new schedule file. Sets the current schedule\_line to 0.>
pro XDIConsole::file_change_sched, event  ;\A\<Widget event>
	 self.runtime.schedule = dialog_pickfile(path = self.misc.default_settings_path)
	 self.misc.schedule_line = 0
end

;\D\<Initialize the camera.>
pro XDIConsole::cam_initialize, event  ;\A\<Widget event>

	;\\ Initialise the camera
		status = 0
		res = get_error(call_external(self.misc.dll_name, 'uGetStatus', status))
		if res eq 'DRV_NOT_INITIALIZED' then begin
			self->log, 'Initializing camera: ' + get_error(call_external(self.misc.dll_name, 'uInitialize', 'c:\testcode')), 'Console', /display
		endif else begin
			self->log, 'Camera already initialized', 'Console', /display
		endelse

	;\\ Update the camera (usually done automatically, but not during startup)
		commands = ['uSetShutter', 'uSetReadMode', 'uSetImage', 'uSetAcquisitionMode', $
		            'uSetFrameTransferMode', 'uSetPreAmpGain', 'uSetEMGainMode', 'uSetVSAmplitude', 'uSetBaselineClamp', 'uSetADChannel', 'uSetOutputAmplifier', 'uSetTriggerMode', 'uSetHSSpeed', $
					'uSetVSSpeed', 'uSetExposureTime', 'uSetTemperature', 'uGetTemperatureRange', 'uSetGain', 'uSetFanMode']
		if self.camera.cooler_on eq 1 then commands = [commands, 'uCoolerON'] else commands = [commands, 'uCoolerOFF']
		self -> update_camera, commands, results

		res = call_external(self.misc.dll_name, 'uAbortAcquisition')
		temp = 0.0;
		res = call_external(self.misc.dll_name, 'uGetTemperatureF', temp, val=[0b])
		self.camera.cam_temp = temp
		self.camera.temp_state = get_error(res)
		res = call_external(self.misc.dll_name, 'uStartAcquisition')

		res = call_external(self.misc.dll_name, 'uStartAcquisition')


end

;\D\<Shutdown the camera. If cooler is running, will flag that we need to wait for the cam temp to>
;\D\<reach a safe level before doing a final shutdown.>
pro XDIConsole::cam_shutdown, event  ;\A\<Widget event>

	if size(event, /type) eq 7 then begin
		if event eq 'console closed' then log = 0
	endif else begin
		log = 1
	endelse

	temp = self.camera.cam_temp
	safe_str = string(self.camera.cam_safe_temp, f='(f0.1)')

	if log eq 1 then begin

		if temp lt self.camera.cam_safe_temp then begin
			self->log, 'Camera temp is lower than ' + safe_str + ' degrees!', 'Console', /display
			res = call_external(self.misc.dll_name, 'uAbortAcquisition')
			res = call_external(self.misc.dll_name, 'uCoolerOFF')
			self->log, 'Cooler is being turned off - ' + get_error(res), 'Console', /display
			self->log, 'Camera will shutdown when temp reaches ' + safe_str + ' degrees', 'Console', /display
			self.camera.wait_for_min_temp = 1
		endif else begin
			res = call_external(self.misc.dll_name, 'uAbortAcquisition')
			res = call_external(self.misc.dll_name, 'uSetShutter', 1, 2L, self.camera.shutter_closing_time, self.camera.shutter_opening_time)
			res = call_external(self.misc.dll_name, 'uShutDown')
			self->log, 'Cam temp is ' + string(temp,f='(f0.2)') + ', Shutting Down...' + get_error(res), 'Console', /display
		endelse

	endif else begin

		if temp lt self.camera.cam_safe_temp then begin
			res = call_external(self.misc.dll_name, 'uAbortAcquisition')
			res = call_external(self.misc.dll_name, 'uCoolerOFF')
			mess = ['Camera temp is lower than ' + safe_str + ' degrees!','Cooler is being turned off - ' + get_error(res), $
					 'Camera will shutdown when temp reaches ' + safe_str + ' degrees']
			warn = dialog_message(mess)
			self.camera.wait_for_min_temp = 1
			self.camera.wait_for_shutdown = 1
		endif else begin
			res = call_external(self.misc.dll_name, 'uAbortAcquisition')
			res = call_external(self.misc.dll_name, 'uSetShutter', 1, 2L, self.camera.shutter_closing_time, self.camera.shutter_opening_time)
			res = call_external(self.misc.dll_name, 'uShutDown')
			warn = dialog_message('Cam temp is ' + string(temp,f='(f0.2)') + ', Shutting Down...' + get_error(res), title = 'SDI CONSOLE MESSAGE')
		endelse

	endelse

end

;\D\<Close the camera shutter.>
pro XDIConsole::cam_shutterclose, event, $               ;\A\<Widget event>
                                  shutdown=shutdown      ;\A\<Flag to indicate we are shutting down the camera>

	if self.runtime.shutter_state eq 1 then begin
		res = call_external(self.misc.dll_name, 'uAbortAcquisition')
		res = call_external(self.misc.dll_name, 'uSetShutter', 1L, 2L, long(self.camera.shutter_closing_time), long(self.camera.shutter_opening_time))
		if self.runtime.mode ne 'auto' then self->log, 'Shutter Close - ' + get_error(res), 'Console', /display
		if get_error(res) eq 'DRV_SUCCESS' then self.runtime.shutter_state = 0
	endif

	if not keyword_set(shutdown) then begin
		if self.runtime.shutter_state eq 0 then shutter_string = 'CLOSED' else shutter_string = 'OPEN'
		shutter_id = widget_info(self.misc.console_id, find_by_uname = 'console_shutter_guage')
		widget_control, set_value = 'Shutter: ' + shutter_string, shutter_id
		res = call_external(self.misc.dll_name, 'uStartAcquisition')
	endif

end

;\D\<Open the camera shutter>
pro XDIConsole::cam_shutteropen, event  ;\A\<Widget event>

	if self.runtime.shutter_state eq 0 then begin
		res = call_external(self.misc.dll_name, 'uAbortAcquisition')
		res = call_external(self.misc.dll_name, 'uSetShutter', 1L, 1L, long(self.camera.shutter_closing_time), long(self.camera.shutter_opening_time))
		if self.runtime.mode ne 'auto' then  self->log, 'Shutter Open - ' + get_error(res), 'Console', /display
		if get_error(res) eq 'DRV_SUCCESS' then self.runtime.shutter_state = 1
	endif

	if self.runtime.shutter_state eq 0 then shutter_string = 'CLOSED' else shutter_string = 'OPEN'
	shutter_id = widget_info(self.misc.console_id, find_by_uname = 'console_shutter_guage')
	widget_control, set_value = 'Shutter: ' + shutter_string, shutter_id

	res = call_external(self.misc.dll_name, 'uStartAcquisition')

end

;\D\<Fills up some variables with the current values of \verb"cam_temp, temp_state, cooler_temp".>
pro XDIConsole::get_camera_temp, temp, $         ;\A\<OUT: camera temp currently stored in settings>
                                 temp_state, $   ;\A\<OUT: camera temp state currently stored in settings>
                                 set_point       ;\A\<OUT: camera cooler temp set point currently stored in settings>

	temp = self.camera.cam_temp
	temp_state = self.camera.temp_state
	set_point = self.camera.cooler_temp

end

;\D\<Return the processed camera image currently stored in the console buffer.>
function XDIConsole::get_image, image  ;\A\<No idea why this argument is here>

	return, *self.buffer.image

end

;\D\<Return the raw camera image currently stored in the console buffer.>
function XDIConsole::get_raw_image, image  ;\A\<No idea why this argument is here>

	return, *self.buffer.raw_image

end

;\D\<Interface for starting, stopping and pausing etalon scans.>
pro XDIConsole::scan_etalon, caller, $                                ;\A\<String identifying who is calling this function>
                             start_scan=start_scan, $                 ;\A\<Flag to start a new scan>
                             stop_scan=stop_scan, $                   ;\A\<Flag to stop a scan>
                             pause_scan=pause_scan, $                 ;\A\<Flag to pause a scan>
                             cont_scan=cont_scan, $                   ;\A\<Flag to continue a paused scan>
                             start_volt_offset=start_volt_offset, $   ;\A\<For manual scans, the start offset>
                             stop_volt_offset=stop_volt_offset, $     ;\A\<For manual scans, the stop offset>
                             volt_step_size=volt_step_size, $         ;\A\<For manual scans, the volt step size>
                             status=status, $                         ;\A\<OUT: result of the call>
                             reference=reference, $                   ;\A\<OUT: a reference image at zero offset>
                             get_ref=get_ref, $                       ;\A\<Flag to indicate that we want a reference image (need to also supply reference keyword)>
                             wavelength=wavelength, $                 ;\A\<Wavelength to scan at>
                             force_start=force_start                  ;\A\<Force a scan to start even if already scanning>

	status = ''

	if keyword_set(start_scan) then begin
		if (self.etalon.scanning eq 1 or self.etalon.scanning eq 2) and not(keyword_set(force_start)) then begin
			;\\ Etalon already in use
				if self.runtime.mode eq 'manual' then begin
					mess = 'Etalon is already being scanned by another plugin!'
					res = dialog_message(mess, /info)
				endif else begin
					print, 'Etalon already in use'
				endelse
				self->log, caller + ' attempted to start scanner - already in use', 'Console', /display
				status = 'Could not initiate'
		endif else begin
			;\\ Start the scanner

				status = 1

				;\\ If a reference image is required, supply this
					if keyword_set(get_ref) then begin
						self.etalon.start_volt_offset = 0
						self.etalon.current_channel = 0
						self -> update_legs
						reference = self -> force_image_update()
					endif

				if size(start_volt_offset, /type) ne 0 and $
				   size(stop_volt_offset, /type) ne 0 and $
				   size(volt_step_size, /type) ne 0 then begin
					self.etalon.volt_step_size = volt_step_size > 1.0
					self.etalon.start_volt_offset = start_volt_offset
					self.etalon.stop_volt_offset = stop_volt_offset
				endif else begin
					self.etalon.volt_step_size = self.etalon.nm_per_step*wavelength > 1.0
				endelse

				if self.etalon.leg1_offset eq 0.0 then self.etalon.leg1_offset = 1.0
				if self.etalon.leg2_offset eq 0.0 then self.etalon.leg2_offset = 1.0
				if self.etalon.leg3_offset eq 0.0 then self.etalon.leg3_offset = 1.0

				status = 'Scanner started'

			;\\ Set the legs to their initial values
				self -> update_legs
				resx = call_external(self.misc.dll_name, 'uAbortAcquisition')
				resx = call_external(self.misc.dll_name, 'uFreeInternalMemory')
				resx = call_external(self.misc.dll_name, 'uStartAcquisition')
				;res = self -> force_image_update()

				self.etalon.scanning = 1
				self.etalon.current_channel = 0

		endelse
		goto, END_SCAN_ETALON
	endif

	if keyword_set(stop_scan) then begin
		if self.etalon.scanning eq 0 then begin
			;\\ No scan to stop
				if self.runtime.mode eq 'manual' then begin
					mess = 'There is no scan to terminate!'
					;res = dialog_message(mess, /info)
				endif else begin
					print, 'No scan to terminate!'
				endelse
				self->log, caller + ' attempted to stop scanner - no scan running', 'Console', /display
				status = 'No scan to stop'
		endif else begin
			;\\ Stop the scanner
				self.etalon.start_volt_offset = 0
				self.etalon.stop_volt_offset  = 0
				self.etalon.volt_step_size    = 0.0
				self.etalon.current_channel   = 0
				self.etalon.scanning = 0

				status = 'Scanner stopped'
		endelse
		goto, END_SCAN_ETALON
	endif

	if keyword_set(pause_scan) then begin
		if self.etalon.scanning eq 0 then begin
			;\\ No scan to pause
				if self.runtime.mode eq 'manual' then begin
					mess = 'There is no scan to pause!'
					;res = dialog_message(mess, /info)
				endif else begin
					print, 'No scan to pause!'
				endelse
				self->log, caller + ' attempted to pause scanner - no scan running', 'Console', /display
				status = 'No scan to pause'
		endif else begin
			;\\ Pause the scanner
				self.etalon.scanning = 2

				status = 'Scanner paused'
		endelse
		goto, END_SCAN_ETALON
	endif

	if keyword_set(cont_scan) then begin
		if self.etalon.scanning ne 2 then begin
			;\\ No scan to continue
				if self.runtime.mode eq 'manual' then begin
					mess = 'There is no paused scan to continue!'
					;res = dialog_message(mess, /info)
				endif else begin
					print, 'No paused scan to continue!'
				endelse
				self->log, caller + ' attempted to continue scanner - no scan paused', 'Console', /display
				status = 'No paused scan to continue'
		endif else begin
			;\\ Cont the scanner
				self.etalon.scanning = 1

				status = 'Scanner continued'
		endelse
		goto, END_SCAN_ETALON
	endif

END_SCAN_ETALON:
end

;\D\<Force the camera grab a new image (sometimes used when acquiring reference images).>
function XDIConsole::force_image_update

	if self.camera.acquisition_mode eq 1 then begin
		if self.camera.temp_state ne 'CAMERA IS SHUT DOWN!!' then begin
			status = 0
			res = call_external(self.misc.dll_name, 'uGetStatus', status)

			template_image = *self.buffer.image
			x_dim = n_elements(template_image(*,0))
			y_dim = n_elements(template_image(0,*))

			image = lonarr(x_dim,y_dim)
			im_size = long(float(x_dim) * float(y_dim))

			res = call_external(self.misc.dll_name, 'uAbortAcquisition')
			res = call_external(self.misc.dll_name, 'uStartAcquisition')
			res = call_external(self.misc.dll_name, 'uWaitForAcquisition')
			res = call_external(self.misc.dll_name, 'uGetMostRecentImage', image, im_size)
			res = call_external(self.misc.dll_name, 'uStartAcquisition')

			image = ulong(image)
			*self.buffer.raw_image = ulong(image)
			call_procedure, self.header.instrument_name + '_imageprocess', image
			*self.buffer.image = ulong(image)

		endif else begin
			image = *self.buffer.image
		endelse
	endif else begin
		template_image = *self.buffer.image
		x_dim = n_elements(template_image(*,0))
		y_dim = n_elements(template_image(0,*))

		if n_elements(image) eq 0   then image = lonarr(x_dim,y_dim)
		if n_elements(img_buf) eq 0 then img_buf = lonarr(x_dim,y_dim)
		im_size = ulong(float(x_dim) * float(y_dim))

		resx = call_external(self.misc.dll_name, 'uAbortAcquisition')
		resx = call_external(self.misc.dll_name, 'uFreeInternalMemory')
		resx = call_external(self.misc.dll_name, 'uStartAcquisition')
		wait, .5
		nframes = 0
        repeat begin
			res = call_external(self.misc.dll_name, 'uGetOldestImage', img_buf, im_size)
			if nframes eq 0 then image = img_buf else image = image + img_buf
			nframes = nframes + 1
			firstim = 0L
			lastim = 0L
			res = get_error(call_external(self.misc.dll_name, 'uGetNumberNewImages', firstim, lastim, value=[0b, 0b]))
		endrep until firstim eq lastim
		image = (image)/nframes

		image = ulong(image)
		*self.buffer.raw_image = ulong(image)
		call_procedure, self.header.instrument_name + '_imageprocess', image
		*self.buffer.image = ulong(image)

	endelse
	return, image

end

;\D\<Show the phase map.>
pro XDIConsole::see_calibration, event  ;\A\<Widget event>

	now_time = dt_tm_tojs(systime())
	phase_lag_hours = (now_time - self.etalon.phasemap_time)/3600.
	nm_step_lag_hours = (now_time - self.etalon.nm_per_step_time)/3600.

	js2ymds, self.etalon.phasemap_time, y, m, d, s
	pmap_stamp = string(d, f='(i2.2)') + '/' + string(m, f='(i2.2)') + '/' + string(y, f='(i4.4)')
	pmap_stamp = pmap_stamp + '  @  ' + string(s/3600., f='(i2.2)') + ':' + string(((s/3600.) mod 1)*60., f='(i2.2)')

	js2ymds, self.etalon.nm_per_step_time, y, m, d, s
	nm_stamp = string(d, f='(i2.2)') + '/' + string(m, f='(i2.2)') + '/' + string(y, f='(i4.4)')
	nm_stamp = nm_stamp + '  @  ' + string(s/3600., f='(i2.2)') + ':' + string(((s/3600.) mod 1)*60., f='(i2.2)')

	pmap = *self.etalon.phasemap_base
	window, /free, xs=n_elements(pmap(*,0)) + 100, ys=n_elements(pmap(0,*)) + 100
	loadct, 0, /silent
	tvscl, pmap, 100, 100, /device

	hx_section = pmap(*, n_elements(pmap(*,0))/2.)
	vx_section = pmap(n_elements(pmap(0,*))/2., *)

	plot, vx_section, indgen(n_elements(pmap(0,*))), position = [5,100,95,n_elements(pmap(0,*))+100], $
		  /device, xstyle=5, ystyle=5, /noerase, thick = 2
	plot, indgen(n_elements(pmap(0,*))), hx_section, position = [100,5,n_elements(pmap(*,0))+100,95], $
		  /device, xstyle=5, ystyle=5, /noerase, thick = 2

	loadct, 39, /silent
    xyouts, /device, 120, 300, 'Phasemap generated on: ' + pmap_stamp, chars = 1, chart = 1.5, color = 200
    xyouts, /device, 120, 250, 'Volts/channel/nm = ' + string(self.etalon.nm_per_step, f='(f0.5)'), $
    							chars = 1, chart = 1.5, color = 200
    xyouts, /device, 120, 220, 'Generated on: ' + nm_stamp, chars = 1, chart = 1.5, color = 200
    plots, /device, [0,n_elements(pmap(*,0))+100], [100,100], color = 200, thick = 2
    plots, /device, [100,100], [0,n_elements(pmap(0,*))+100], color = 200, thick = 2


end

;\D\<Set the camera exposure time.>
pro XDIConsole::cam_exptime, event, $               ;\A\<Widget event>
                             new_time=new_time      ;\A\<Use this to supply the new time, instead of asking for it>

	if self.etalon.scanning eq 0 then begin

		if not keyword_set(new_time) then begin
			exp_time = self.camera.exposure_time
			exp_time = inputbox(exp_time, title = "Set Exposure Time (Seconds)", group = self.misc.console_id)
			self.camera.exposure_time = exp_time
		endif else begin
			self.camera.exposure_time = new_time
		endelse

		commands = ['uSetExposureTime']
		self -> update_camera, commands, results

		exp_time_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_exp_time_guage')
		widget_control, set_value = 'Exp Time: ' + string(self.camera.exposure_time, f='(f0.3)') + ' s', exp_time_guage_id

	endif else begin
		res = dialog_message('Etalon is scanning!')
	endelse

end

;\D\<Set the camera EM gain.>
pro XDIConsole::cam_gain, event, $               ;\A\<Widget event>
                          new_gain=new_gain      ;\A\<Use this to supply the new gain, instead of asking for it>

	if self.etalon.scanning eq 0 then begin

		if not keyword_set(new_gain) then begin
			gain = self.camera.gain
			;xvaredit, gain, name='Enter gain value (0-255)', group=self.misc.console_id
			gain = inputbox(gain, title = "Set Gain", group = self.misc.console_id)
			self.camera.gain = gain
		endif else begin
			self.camera.gain = new_gain
		endelse

		commands = ['uSetGain']
		self -> update_camera, commands, results

		gain_guage_id  = widget_info(self.misc.console_id, find_by_uname = 'console_gain_guage')
		widget_control, set_value = 'Gain: ' + string(self.camera.gain, f='(i0)'), gain_guage_id

	endif else begin
		res = dialog_message('Etalon is scanning!')
	endelse

end

;\D\<FTP a data snapshot provided by a spectrum plugin back to an SFTP server using PSFTP. The>
;\D\<server and login info is store in \verb"logging.ftp_snapshot", for example:>
;\D\<"137.111.22.333 -l username -pw password here".>
pro XDIConsole::spectrum_snapshot, snapshot  ;\A\<The data snapshot>

	;\\ Example logging.ftp_snapshot:
	;\\ '137.229.27.190 -l instrument -pw aer0n0my'

	if self.logging.ftp_snapshot ne '' then begin

		;\\ Write out a snapshot into an IDL save file, and FTP
		snapshot = create_struct(snapshot, 'site_code', self.header.site_code)

		save_name = self.logging.log_directory + self.header.site_code + $
					'_' + string(snapshot.wavelength, f='(i04)') + '_snapshot.idlsave'
		save, filename = save_name, snapshot, /compress
		openw, hnd, 'c:\users\sdi3000\ftp_snapshot.bat', /get
		printf, hnd, 'put ' + save_name
		printf, hnd, 'exit'
		free_lun, hnd
		spawn, 'c:\users\sdi3000\sdi\bin\psftp.exe ' + self.logging.ftp_snapshot + ' -b ' + $
			   'c:\users\sdi3000\ftp_snapshot.bat', /nowait, /hide

	endif
end

;\D\<Called from timer_event, sends back status information to the SDI server.>
pro XDIConsole::status_update

	common XDIConsoleStatusUpdate, last_status_update0, last_status_update1

	if n_elements(last_status_update0) eq 0 then last_status_update0 = 0d
	if n_elements(last_status_update1) eq 0 then last_status_update1 = 0d

	if self.logging.ftp_snapshot ne '' then begin

		;\\ Send status update
		if ( (systime(/sec) - last_status_update0)/60. gt 20. ) then begin

			;\\ Make a png of the current phasemap
			self -> get_phasemap, base, grad, lambda
			phmap = float(base) * (lambda/630.0) * grad
			write_png, 'c:\users\sdi3000\status_phasemap.png', phmap

			;\\ Get some log file paths
			time = convert_js(dt_tm_tojs(systime(/ut)))
			log_path = self.logging.log_directory + '\' + ymd2string( time.year, time.month, time.day, separator='_')
			console_log = log_path + '\console_log.txt'
			instr_log = log_path + '\instrumentspecific_log.txt'
			spectrum_log = log_path + '\spectrum_log.txt'


			openw, hnd, 'c:\users\sdi3000\ftp_status_update.bat', /get
			printf, hnd, 'put c:/users/sdi3000/status_phasemap.png /status/' + self.header.site_code + '/phasemap.png'
			printf, hnd, 'put ' + self.runtime.schedule + ' /status/' + self.header.site_code + '/schedule.txt'
			if file_test(console_log) then printf, hnd, 'put ' + console_log + ' /status/' + self.header.site_code + '/console_log.txt'
			if file_test(instr_log) then printf, hnd, 'put ' + instr_log + ' /status/' + self.header.site_code + '/instrumentspecific_log.txt'
			if file_test(spectrum_log) then printf, hnd, 'put ' + spectrum_log + ' /status/' + self.header.site_code + '/spectrum_log.txt'
			printf, hnd, 'exit'
			free_lun, hnd
			spawn, 'c:\users\sdi3000\sdi\bin\psftp.exe ' + self.logging.ftp_snapshot + ' -b ' + $
				   'c:\users\sdi3000\ftp_status_update.bat', /nowait, /hide

			last_status_update0 = systime(/sec)

		endif

		;\\ Send more regular stuff
		if ( (systime(/sec) - last_status_update1)/60. gt 2. ) then begin

			;\\ Get the current software version from git (most recent git commit on master branch)
			spawn, 'cd c:/users/sdi3000/sdi & git log --oneline -1', result
			software_version = strtrim(result)

			openw, hnd, 'c:\users\sdi3000\status_info.txt', /get
			printf, hnd, 'SiteCode=' + self.header.site_code
			printf, hnd, 'SystemUT=' + systime(/ut)
			printf, hnd, 'SunElevationDeg=' + string(get_sun_elevation(self.header.latitude, self.header.longitude), f='(f0.2)')
			printf, hnd, 'FreeDiskSpaceCGb=' + string(self->FreeDiskSpace('c:\', /gb), f='(f0.2)')
			printf, hnd, 'PhasemapAgeHours=' + string( (dt_tm_tojs(systime()) - self.etalon.phasemap_time)/3600., f='(f0.2)')
			printf, hnd, 'ScheduleLine=' + string(self.misc.schedule_line, f='(i0)')
			printf, hnd, 'LastScheduleCommand=' + self.runtime.last_schedule_command
			printf, hnd, 'MotorSkyPos=' + string(self.misc.motor_sky_pos, f='(i0)')
			printf, hnd, 'MotorCalPos=' + string(self.misc.motor_cal_pos, f='(i0)')
			printf, hnd, 'MotorCurPos=' + string(self.misc.motor_cur_pos, f='(i0)')
			printf, hnd, 'CurrentFilter=' + string(self.misc.current_filter, f='(i0)')
			printf, hnd, 'CurrentCalSource=' + string(self.misc.current_source, f='(i0)')
			printf, hnd, 'CameraExposureTime=' + string(self.camera.exposure_time, f='(f0.2)')
			printf, hnd, 'CameraGain=' + string(self.camera.gain, f='(i0)')
			printf, hnd, 'CurrentStatus=' + self.runtime.current_status
			printf, hnd, 'OperatingMode=' + self.runtime.mode
			printf, hnd, 'SoftwareVersion=' + software_version
			free_lun, hnd

			openw, hnd, 'c:\users\sdi3000\ftp_status_update_regular.bat', /get
			printf, hnd, 'put c:\users\sdi3000\status_info.txt /status/' + self.header.site_code + '/status.txt'
			printf, hnd, 'exit'
			free_lun, hnd
			spawn, 'c:\users\sdi3000\sdi\bin\psftp.exe ' + self.logging.ftp_snapshot + ' -b ' + $
				   'c:\users\sdi3000\ftp_status_update_regular.bat', /nowait, /hide

			last_status_update1 = systime(/sec)
		endif

	endif else begin
		last_status_update0 = systime(/sec)
		last_status_update1 = systime(/sec)
	endelse
end

;\D\<Get the free space (in Mb by default, use keyword for Gb) in the given path.>
function XDIConsole::FreeDiskSpace, path, gb=gb
  spawn, 'dir ' + path + ' | find "free"', res, err, /hide
  out = strsplit(res, ' ', /extract)
  out = strsplit(out[2], ',', /extract)
  space = ''
  for j = 0, n_elements(out) - 1 do space += out[j]
  space = double(space)
  space_mb = space / 1048576.
  space_gb = space / 1073741824.
  if keyword_set(gb) then return, space_gb else return, space_mb
end

;\D\<Spectrum plugins call this when creating new netcdf files.>
function XDIConsole::get_spec_save_info, nrings  ;\A\<Number of rings in the zonemap>

	pmap_dims = size(*self.etalon.phasemap_base, /dimensions)

	spec_save_info = {zone_radii:fltarr(nrings), $
					zone_sectors:intarr(nrings-1), $
						x_center:self.camera.xcen, $
						y_center:self.camera.ycen, $
						   x_bin:self.camera.xbin, $
						   y_bin:self.camera.ybin, $
						   x_pix:self.camera.xpix, $
						   y_pix:self.camera.ypix, $
						cam_temp:self.camera.cam_temp, $
						cam_gain:self.camera.gain, $
					 cam_exptime:self.camera.exposure_time, $
						     gap:self.etalon.gap, $
					 nm_per_step:self.etalon.nm_per_step, $
			gap_refractive_index:self.etalon.gap_refractive_index, $
					  wavelength:0.0, $
				 leg1_start_volt:self.etalon.leg1_base_voltage, $
				 leg2_start_volt:self.etalon.leg2_base_voltage, $
				 leg3_start_volt:self.etalon.leg3_base_voltage, $
				 	 leg1_offset:self.etalon.leg1_offset, $
				 	 leg2_offset:self.etalon.leg2_offset, $
				 	 leg3_offset:self.etalon.leg3_offset, $
				   scan_channels:self.etalon.number_of_channels, $
				   		phasemap:intarr(pmap_dims[0], pmap_dims[1])}

	return, spec_save_info

end

;\D\<Return a copy of the the \verb"self" data structure.>
function XDIConsole::get_console_data

	return, {console_id:self, $
			 etalon:self.etalon, $
		     camera:self.camera, $
		     header:self.header, $
		     logging:self.logging, $
		     misc:self.misc, $
			 runtime:self.runtime, $
			 buffer:self.buffer }

end

;\D\<Return the \verb"header" structure.>
function XDIConsole::get_header_info

	return, self.header

end

;\D\<Return the \verb"etalon" structure.>
function XDIConsole::get_etalon_info

	return, self.etalon

end

;\D\<Return the \verb"logging" structure.>
function XDIConsole::get_logging_info

	return, self.logging

end

;\D\<Return the palette.>
function XDIConsole::get_palette

	return, self.misc.palette

end

;\D\<Return the port map structure.>
function XDIConsole::get_port_map

	return, self.misc.port_map

end

;\D\<Return the current phasemap path (where a copy of each phasemap is saved to).>
function XDIConsole::get_phase_map_path

	return, self.misc.phase_map_path

end

;\D\<Return the path where zone map settings files are stored.>
function XDIConsole::get_zone_set_path

	return, self.misc.zone_set_path

end

;\D\<Return the path where spectrum data stored.>
function XDIConsole::get_spectra_path

	return, self.misc.spectra_path

end

;\D\<Return the default settings path (for plugin settings files).>
function XDIConsole::get_default_path

	return, self.misc.default_settings_path

end

;\D\<Get the format string used to create netcdf file names in the spectral plugins.>
function XDIConsole::get_time_name_format

	js = dt_tm_tojs(systime())
	js2ymds, js, y, m, d, s
	js0 = ymds2js(y,m,d,0)
	jd0 = js2jd(js0)
	date_str = dt_tm_mk(jd0, s, format = self.logging.time_name_format)

	return, date_str

end

;\D\<Set a new value for the steps per order.>
pro XDIConsole::set_nm_per_step, nm_per_step  ;\A\<New nm per step value>

	self.etalon.nm_per_step = nm_per_step
	self.etalon.nm_per_step_time = dt_tm_tojs(systime())

end

;\D\<Set new phasemap information (multiple info is required for interpolating).>
pro XDIConsole::set_phasemap, phasemap_base, $     ;\A\<Phasemap recorded at the lower wavelength>
                              phasemap_grad, $     ;\A\<`Gradient' used when interpolating>
                              phasemap_lambda      ;\A\<Wavelength at which the base phasemap was recorded (the smaller of the two lambdas)>

	*self.etalon.phasemap_base = phasemap_base
	*self.etalon.phasemap_grad = phasemap_grad
	 self.etalon.phasemap_lambda = phasemap_lambda
	 self.etalon.phasemap_time = dt_tm_tojs(systime())

end

;\D\<Get the phase map info.>
pro XDIConsole::get_phasemap, phasemap_base, $     ;\A\<OUT: phasemap base>
                              phasemap_grad, $     ;\A\<OUT: phasemap gradient>
                              phasemap_lambda      ;\A\<OUT: wavelength of phasemap base>

	phasemap_base = *self.etalon.phasemap_base
	phasemap_grad = *self.etalon.phasemap_grad
	phasemap_lambda = self.etalon.phasemap_lambda

end

;\D\<I don't think this has ever been used, but it is meant to force all active spectral>
;\D\<plugins to refresh their phasemaps, if for example a phase map refresh was called>
;\D\<during observations.>
pro XDIConsole::refresh_spec_pmaps

	struc = self.manager -> generate_list()

	pts = where(strlowcase(strmid(struc.type,0,8)) eq 'spectrum', nspex)

	for n = 0, nspex - 1 do begin
		failed = 0
		struc.ref(pts(n)) -> set_phasemap, failed
	endfor

end

;\D\<Set the camera image center pixels.>
pro XDIConsole::set_center, xcen, $   ;\A\<X center>
                            ycen      ;\A\<Y center>

	self.camera.xcen = xcen
	self.camera.ycen = ycen

end

;\D\<Set the structure which defines the mapping between source position and wavelength.>
pro XDIConsole::set_source_map, smap  ;\A\<New source map>

	self.misc.source_map = smap

end

;\D\<Get the structure which defines the mapping between source position and wavelength.>
pro XDIConsole::get_source_map, smap  ;\A\<OUT: current source map>

	smap = self.misc.source_map

end

;\D\<Get the name of the SDI\_External dll.>
function XDIConsole::get_dll_name

	return, self.misc.dll_name

end

;\D\<Get the current value of snr per scan.>
function XDIConsole::get_snr_per_scan

	return, self.runtime.snr_per_scan

end

;\D\<Set a new value for snr/scan,>
pro XDIConsole::set_snr_per_scan, snr  ;\A\<New snr value>

	self.runtime.snr_per_scan = snr

end

;\D\<Home the mirror motor to the sky viewing position. Calls instrument-specific file.>
pro XDIConsole::mot_home_sky, event  ;\A\<Widget event>

	call_procedure, self.header.instrument_name + '_mirror', home_motor = 'sky', self.misc, self
	fpos = 1L
	call_procedure, self.header.instrument_name + '_mirror', read_pos = fpos, self.misc, self

	self.misc.motor_sky_pos = fpos
	self.misc.motor_cur_pos = fpos
	motor_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
	widget_control, set_value = 'MotorPos: ' + string(fpos,f='(i0)'), motor_guage_id
	self -> save_current_settings
	self->log, 'Sky Position Reached: ' + string(fpos, f='(i0)'), 'Console', /display

end

;\D\<Home the mirror motor to the calibration viewing position. Calls instrument-specific file.>
pro XDIConsole::mot_home_cal, event  ;\A\<Widget event>

	call_procedure, self.header.instrument_name + '_mirror', home_motor = 'cal', self.misc, self
	fpos = 1L
	call_procedure, self.header.instrument_name + '_mirror', read_pos = fpos, self.misc, self

	self.misc.motor_cal_pos = fpos
	call_procedure, self.header.instrument_name + '_mirror', drive_to_pos = fpos, $
															 self.misc, $
															 self

	self.misc.motor_cur_pos = fpos
	motor_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
	widget_control, set_value = 'MotorPos: ' + string(fpos,f='(i0)'), motor_guage_id
	self -> save_current_settings
	self->log, 'Cal Position Reached: ' + string(fpos, f='(i0)'), 'Console', /display

end

;\D\<Drive the mirror motor to the sky viewing position. Calls instrument-specific file.>
pro XDIConsole::mot_drive_sky, event  ;\A\<Widget event>

	call_procedure, self.header.instrument_name + '_mirror', drive_to_pos = self.misc.motor_sky_pos, $
															 self.misc, $
															 self

	self.misc.motor_cur_pos = self.misc.motor_sky_pos
	self -> save_current_settings
	motor_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
	widget_control, set_value = 'MotorPos: ' + string(self.misc.motor_sky_pos,f='(i0)'), motor_guage_id
	self->log, 'Sky Position Reached: ' + string(self.misc.motor_sky_pos, f='(i0)'), 'Console', /display

end

;\D\<Home the mirror motor to the calibration viewing position. Calls instrument-specific file.>
pro XDIConsole::mot_drive_cal, event  ;\A\<Widget event>

	call_procedure, self.header.instrument_name + '_mirror', drive_to_pos = self.misc.motor_cal_pos, $
															 self.misc, $
															 self

	self.misc.motor_cur_pos = self.misc.motor_cal_pos
	self -> save_current_settings
	motor_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
	widget_control, set_value = 'MotorPos: ' + string(self.misc.motor_cal_pos,f='(i0)'), motor_guage_id
	self->log, 'Cal Position Reached: ' + string(self.misc.motor_cal_pos, f='(i0)'), 'Console', /display

end

;\D\<Drive the mirror motor to an arbitrary location.>
pro XDIConsole::mot_drive_mirror_to, event  ;\A\<Widget event>

	title =  'CAREFUL! Set Mirror Absolute Position (' + string(self.misc.motor_cal_pos, f='(i0)') + $
			 ' (cal) - ' + string(self.misc.motor_sky_pos, f='(i0)') + ' (sky))'
	drive_to_pos = self.misc.motor_cal_pos
	drive_to_pos = inputBox(drive_to_pos, title = title, group=self.misc.console_id)

	if (drive_to_pos le self.misc.motor_cal_pos	or drive_to_pos ge self.misc.motor_sky_pos) then begin
		res = dialog_message('Position is not between CAL-SKY limits! Skipping...')
		return
	endif

	call_procedure, self.header.instrument_name + '_mirror', drive_to_pos = drive_to_pos, $
															 self.misc, $
															 self
	fpos = 1L
	call_procedure, self.header.instrument_name + '_mirror', read_pos = fpos, self.misc, self

	self.misc.motor_cur_pos = fpos
	self -> save_current_settings
	motor_guage_id = widget_info(self.misc.console_id, find_by_uname = 'console_motor_guage')
	widget_control, set_value = 'MotorPos: ' + string(fpos, f='(i0)'), motor_guage_id
	self->log, 'Position Reached: ' + string(fpos, f='(i0)'), 'Console', /display

end

;\D\<Select a new filter. Calls instrument-specific file.>
pro XDIConsole::mot_sel_filter, event  ;\A\<Widget event>

	;\\ This allows the user to manually select the current filter
		filter = self.misc.current_filter
		filter = inputbox(filter, title = "Select Filter", group = self.misc.console_id)

		if (filter eq self.misc.current_filter) then return

		call_procedure, self.header.instrument_name + '_filter', filter, $
																 log_path = self.logging.log_directory, $
																 self.misc, $
																 self
		self.misc.current_filter = filter
		self -> save_current_settings
end

;\D\<Select a new calibration source, or home it. Calls instrument-specific file.>
pro XDIConsole::mot_sel_cal, event, $                   ;\A\<Widget event>
                             set_source=set_source      ;\A\<Supply the new source number instead of asking for it>

	homing = 0
	source = -1
	if keyword_set(set_source) then begin

		self.misc.current_source = set_source

	endif else begin

		if size(event, /type) eq 8 then begin

			widget_control, get_uval = uval, event.id

			if uval.type eq 'drive' then begin
				;\\ This allows the user to manually select the current source
					source = self.misc.current_source
					source = inputbox(source, title = "Select Cal Source", group = self.misc.console_id)
			endif
			if uval.type eq 'home' then begin
				homing = 1
				source = -1
			endif
		endif else begin
		;\\ Or supply it in the event variable
			source = event
		endelse

		if (source ne self.misc.current_source) or homing eq 1 then begin

			if source ge 0 and source le 4 then self.misc.current_source = source
			if homing eq 1 and source eq -1 then self.misc.current_source = source

			call_procedure, self.header.instrument_name + '_switch', source, $
																	 self.misc, $
																	 self, home=homing

		endif

		source_id = widget_info(self.misc.console_id, find='console_switch_guage')
		widget_control, set_value = 'SwitchPos: ' + string(self.misc.current_source,f='(i0)'), source_id
		self -> save_current_settings

	endelse

end


;\D\<Close the mirror port.>
pro XDIConsole::close_mport, event  ;\A\<Widget event>

	res = drive_motor(self.misc.port_map.mirror.number, self.misc.dll_name, control = 'closeport')

end

;\D\<Open the mirror port.>
pro XDIConsole::open_mport, event  ;\A\<Widget event>

	res = drive_motor(self.misc.port_map.mirror.number, self.misc.dll_name, control = 'openport')

end

;\D\<Cleanup after the console. Call instrument-specific cleanup routine.>
pro XDIConsole::cleanup

	print, 'Console cleanup:'

	;\\ Store the geometry settings
		geometry = widget_info(self.misc.console_id, /geometry)
		save, filename = self.misc.default_settings_path + 'console.sdi', geometry

	print, 'Saved Geometry'

	;\\ Close the camera shutter
		self -> cam_shutterclose, 0, /shutdown

	print, 'Closed Shutter'
	call_procedure, self.header.instrument_name + '_cleanup', self.misc, self
end

;\D\<XDIConsole is the main routine for SDI control. See the software manual for details.>
pro XDIConsole__define

	;\\ Count the plugins
	paths = Get_Paths()
	path_list = file_search(paths + '\SDI*__define.pro', count = nmods)

	;\\ This just gets the proto-types - it is called again in INIT to set values
	xdisettings_template, etalon=etalon, $
						  camera=camera, $
						  header=header, $
						  logging=logging, $
						  misc=misc

	buffer = {ima, image:ptr_new(/alloc), $
				   raw_image:ptr_new(/alloc)}

	runtime = {run, schedule:'', $
	                    mode:'', $
	                settings:'', $
	              start_line:0,  $
	           shutter_state:0,  $
	           	 etalon_file:0L, $
	           homing_motors:0,  $
	            acquire_time:0D, $
	           acquire_start:0D, $
	       current_daynumber:0, $
	        	snr_per_scan:0.0, $
	        plugin_path_list:strarr(nmods), $
	        plugin_name_list:strarr(nmods), $
	          current_status:'', $
	   last_schedule_command:'', $
	                editable:['']}

	void = {XDIConsole, etalon:etalon, $
					    camera:camera, $
					    header:header, $
					   logging:logging, $
					      misc:misc, $
					   runtime:runtime, $
					    buffer:buffer, $
					  inherits XDIBase}
end

