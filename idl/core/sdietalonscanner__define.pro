;\\ Code formatted by DocGen


;\D\<Initialize the EtalonScanner.>
function SDIEtalonScanner::init, data=data, $                     ;\A\<Misc data>
                                 restore_struc=restore_struc      ;\A\<Restored settings>

	self.palette = data.palette
	self.need_timer = 0
	self.need_frame = 1
	self.obj_num = string(data.count, format = '(i0)')
	self.manager = data.manager
	self.console = data.console
	self.nchann = data.nchann

	if data.recover eq 1 then begin

		;\\ Saved settings

		xsize 			= 400	;restore_struc.geometry.xsize
		ysize 			= 400	;restore_struc.geometry.ysize
		xoffset 		= restore_struc.geometry.xoffset
		yoffset 		= restore_struc.geometry.yoffset
		self.wavelength = restore_struc.wavelength

	endif else begin

		;\\ Default settings

		xsize 	= 400
		ysize 	= 400
		xoffset = 100
		yoffset = 100

	endelse

	font = 'Ariel*Bold*20'

	base = widget_base(xsize = xsize, ysize = ysize, xoffset = xoffset, yoffset = yoffset, mbar = menu, $
					   title = 'Etalon Scanner', group_leader = leader)

	start_but = widget_button(base, xo = 10, yo = 10, value = 'Start Scan', uval = {tag:'start_scan'}, font = font, $
							  uname = 'EtalonScanner_'+self.obj_num+'_start', xs = 100)
	pause_but = widget_button(base, xo = 130, yo = 10, value = 'Pause Scan', uval = {tag:'pause_scan'}, font = font, $
							  uname = 'EtalonScanner_'+self.obj_num+'_pause', xs = 100)
	stop_but = widget_button(base, xo = 250, yo = 10, value = 'Stop Scan', uval = {tag:'stop_scan'}, font = font, $
							  uname = 'EtalonScanner_'+self.obj_num+'_stop', xs = 100)

	lambda_but = widget_button(base, xo = 10, yo = 350, value = 'Set Wavelength', uval = {tag:'set_wavelength'}, font = font, $
							  uname = 'EtalonScanner_'+self.obj_num+'_stop', xs = 150)


	leg1_lab = widget_text(base, xo = 10, yo = 50,  value = 'Leg 1: ', font=font, uname = 'EtalonScanner_'+self.obj_num+'_leg1')
	leg2_lab = widget_text(base, xo = 10, yo = 90,  value = 'Leg 2: ', font=font, uname = 'EtalonScanner_'+self.obj_num+'_leg2')
	leg3_lab = widget_text(base, xo = 10, yo = 130, value = 'Leg 3: ', font=font, uname = 'EtalonScanner_'+self.obj_num+'_leg3')
	wave_lab = widget_text(base, xo = 10, yo = 170, value = 'Wavelength: ' + string(self.wavelength,f='(f0.1)'), $
						   uname = 'EtalonScanner_'+self.obj_num+'_wavelength', font=font)
	chan_lab = widget_text(base, xo = 10, yo = 210, value = 'Channel: 0', font=font, $
						   uname = 'EtalonScanner_'+self.obj_num+'_channel')
	stat_lab = widget_text(base, xo = 10, yo = 250, value = 'Status: Ready', font=font, $
						   uname = 'EtalonScanner_'+self.obj_num+'_status')
	time_lab = widget_text(base, xo = 10, yo = 290, value = 'Time: 0', font=font, $
						   uname = 'EtalonScanner_'+self.obj_num+'_timer')


	leglab   = widget_label(base,xo = 0.67*xsize, yo = 0.25*ysize, frame=0, value = "Voltages:", font='Arial*Bold*15')
	leg1bar  = Widget_Draw(base, xo = 0.67*xsize, yo = 0.3*ysize, xsize= 0.04*xsize, ysize = 0.6*ysize, frame=2, $
						   uname = 'EtalonScanner_'+self.obj_num+'_L1scanbar')
	leg2bar  = Widget_Draw(base, xo = 0.71*xsize, yo = 0.3*ysize, xsize= 0.04*xsize, ysize = 0.6*ysize, frame=2, $
						   uname = 'EtalonScanner_'+self.obj_num+'_L2scanbar')
	leg3bar  = Widget_Draw(base, xo = 0.75*xsize, yo = 0.3*ysize, xsize= 0.04*xsize, ysize = 0.6*ysize, frame=2, $
						   uname = 'EtalonScanner_'+self.obj_num+'_L3scanbar')

	scanlab  = widget_label(base,xo = 0.86*xsize, yo = 0.25*ysize, frame=0, value = "Scan:", font='Arial*Bold*15')
	scanbar  = Widget_Draw(base, xo = 0.86*xsize, yo = 0.3*ysize, xsize= 0.06*xsize, ysize = 0.6*ysize, frame=2, $
						   uname = 'EtalonScanner_'+self.obj_num+'_scanbar')

	self.id = base

	widget_control, base, /realize
	return, 1

end

;\D\<Start a scan.>
pro SDIEtalonScanner::start_scan, event  ;\A\<Widget event>

	if self.status ne 'Scanning' then begin

	;\\ Get a wavelength
		w = self.wavelength
		if w eq 0.0 then begin
			repeat begin
				;xvaredit, w, name = 'Enter a wavelength in nm', group = self.id
				w = inputbox(w, title = "Set Wavelength in nm", group = self.id)
			endrep until w ne 0.0
		endif
		self.wavelength = w
		lambda_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_wavelength')
		widget_control, set_value = 'Wavelength: ' + string(w, f='(f0.1)'), lambda_id


	;\\ Begin the scanner
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, wavelength=self.wavelength,  /start_scan

		if status eq 'Scanner started' then begin
			self.start_time = systime(/sec)
			self.status = 'Scanning'
			stat_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_status')
			widget_control, set_value = 'Status: ' + self.status, stat_id
		endif

	endif

end

;\D\<Pause the current scan.>
pro SDIEtalonScanner::pause_scan, event  ;\A\<Widget event>

	if self.status eq 'Scanning' then begin

	;\\ Pause the scanner
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, /pause_scan

		if status eq 'Scanner paused' then begin
			self.status = 'Paused'
			stat_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_status')
			pause_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_pause')
			widget_control, set_value = 'Status: ' + self.status, stat_id
			widget_control, set_value = 'Continue', pause_id
		endif

	goto, END_ETALONSCANNER_PAUSE_SCAN
	endif

	if self.status eq 'Paused' then begin

	;\\ Continue the scanner
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, /cont_scan

		if status eq 'Scanner continued' then begin
			self.status = 'Scanning'
			pause_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_pause')
			widget_control, set_value = 'Pause Scan', pause_id
			stat_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_status')
			widget_control, set_value = 'Status: ' + self.status, stat_id
		endif

	goto, END_ETALONSCANNER_PAUSE_SCAN
	endif

END_ETALONSCANNER_PAUSE_SCAN:
end

;\D\<Stop the current scan (will restart from beginning on next `start')>
pro SDIEtalonScanner::stop_scan, event  ;\A\<Widget event>

	if self.status eq 'Scanning' then begin

	;\\ Stop the scanner
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, /stop_scan

		if status eq 'Scanner stopped' then begin
			self.status = 'Ready'
			stat_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_status')
			widget_control, set_value = 'Status: ' + self.status, stat_id
		endif

	endif

end

;\D\<Set the wavelength for scanning.>
pro SDIEtalonScanner::set_wavelength, event  ;\A\<Widget event>

	w = self.wavelength
	;xvaredit, w, name = 'Enter a wavelength in nm', group = self.id
	w = inputbox(w, title = "Set Wavelength in nm", group = self.id)
	self.wavelength = w
	lambda_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_wavelength')
	widget_control, set_value = 'Wavelength: ' + string(w, f='(f0.1)'), lambda_id

end

;\D\<A new frame has been recieved. Update leg diagrams, decide if we need to start a new scan.>
pro SDIEtalonScanner::frame_event, image, $     ;\A\<The new camera frame>
                                   channel      ;\A\<The current scan channel>

	if self.status eq 'Scanning' then begin
		time = systime(/sec) - self.start_time

		chann_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_channel')
		widget_control, set_value = 'Channel: ' + string(channel, f='(i0)'), chann_id
		time_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_timer')
		widget_control, set_value = 'Time: ' + string(time, f='(f0.1)'), time_id

		etalon = self.console->get_etalon_info()
		leg1_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_leg1')
		widget_control, set_value = 'Leg : ' + string(etalon.leg1_voltage, f='(i0)'), leg1_id
		leg2_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_leg2')
		widget_control, set_value = 'Leg : ' + string(etalon.leg2_voltage, f='(i0)'), leg2_id
		leg3_id = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_leg3')
		widget_control, set_value = 'Leg : ' + string(etalon.leg3_voltage, f='(i0)'), leg3_id
	endif

	if channel eq (self.nchann - 1) then begin

		self.start_time = systime(/sec)

		;\\ Restart the scanner
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, wavelength=self.wavelength,  /start_scan
	endif

	if self.status eq 'Scanning' then begin
		scanbar = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_scanbar')
		leg1bar = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_L1scanbar')
		leg2bar = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_L2scanbar')
		leg3bar = widget_info(self.id, find_by_uname = 'EtalonScanner_'+self.obj_num+'_L3scanbar')

;-------Update the scan bar:
		pal = self.console->get_palette()
		Widget_Control, scanbar, Get_Value=wid
		wset, wid
		fracy = channel/float(self.nchann-1)
		if channel eq 0 then begin
			Polyfill, [0, 0, 1., 1., 0], [0, 1., 1., 0, 0], /Normal, Color=pal.black
			Polyfill, [0.05, 0.05, .95, .95, 0.05],  [0.005, .99, .99, 0.005, 0.005], /normal, color=pal.wheat
		endif
		Polyfill, [0.05, 0.05, .95, .95, 0.05], [0.005, .005+fracy, .005+fracy, 0.005, 0.005], /normal, Color=pal.rose

;-------Update the bars for each of the 3 leg voltages:
		Widget_Control, leg1bar, Get_Value=wid
		wset, wid
		fracy = float(etalon.leg1_voltage)/etalon.max_voltage
		if channel eq 0 then begin
			Polyfill, [0, 0, 1., 1., 0], [0, 1., 1., 0, 0], /Normal, pal.black
			Polyfill, [0.05, 0.05, .95, .95, 0.05],  [0.005, .99, .99, 0.005, 0.005], /normal, color=pal.wheat
		endif
		Polyfill, [0.05, 0.05, .95, .95, 0.05], [0.005, .005+fracy, .005+fracy, 0.005, 0.005], /normal, Color=pal.slate
		Widget_Control, leg2bar, Get_Value=wid
		wset, wid
		fracy = float(etalon.leg2_voltage)/etalon.max_voltage
		if channel eq 0 then begin
			Polyfill, [0, 0, 1., 1., 0], [0, 1., 1., 0, 0], /Normal, pal.black
			Polyfill, [0.05, 0.05, .95, .95, 0.05],  [0.005, .99, .99, 0.005, 0.005], /normal, color=pal.wheat
		endif
		Polyfill, [0.05, 0.05, .95, .95, 0.05], [0.005, .005+fracy, .005+fracy, 0.005, 0.005], /normal, Color=pal.slate

		Widget_Control, leg3bar, Get_Value=wid
		wset, wid
		fracy = float(etalon.leg3_voltage)/etalon.max_voltage
		if channel eq 0 then begin
			Polyfill, [0, 0, 1., 1., 0], [0, 1., 1., 0, 0], /Normal, pal.black
			Polyfill, [0.05, 0.05, .95, .95, 0.05],  [0.005, .99, .99, 0.005, 0.005], /normal, color=pal.wheat
		endif
		Polyfill, [0.05, 0.05, .95, .95, 0.05], [0.005, .005+fracy, .005+fracy, 0.005, 0.005], /normal, Color=pal.slate
	endif
end

;\D\<Select settings to save.>
function SDIEtalonScanner::get_settings

	struc = {id:self.id, wavelength:self.wavelength, geometry:self.geometry, need_timer:self.need_timer, $
			 need_frame:self.need_frame}

	return, struc

end

;\D\<Cleanup, stop any current scans.>
pro SDIEtalonScanner::cleanup, log  ;\A\<No Doc>
	if self.status ne 'Ready' then $
		self.console -> scan_etalon, 'Etalon Scanner (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, /stop_scan

end

;\D\<The EtalonScanner plugin lets you continuously scan the etalon over one order of interference>
;\D\<at a given wavelength, and optionally pause during a scan.>
pro SDIEtalonScanner__define

	void = {SDIEtalonScanner, id:0L, status:'', wavelength:0.0, start_time:0D, nchann:0,  inherits XDIBase}

end
