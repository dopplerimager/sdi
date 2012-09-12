;\\ Code formatted by DocGen


;\D\<Initialize the StepsPerOrder plugin.>
function SDIStepsPerOrder::init, restore_struc=restore_struc, $   ;\A\<Restored settings>
                                 data=data                        ;\A\<Misc data from the console>


	;\\ Generic Settings
		self.need_timer = 0
		self.need_frame = 1
		self.manager 	= data.manager
		self.console 	= data.console
		self.palette	= data.palette
		self.obj_num 	= string(data.count, format = '(i0)')

	;\\ Plugin Specific Settings
		self.nchann = data.nchann
		self.corr = ptr_new(/alloc)
		self.image = ptr_new(/alloc)
		self.ref_image = ptr_new(/alloc)
		self.chord_hist = ptr_new(/alloc)
		self.xdim = data.xdim
		self.ydim = data.ydim
		self.record_file = (data.console->get_logging_info()).log_directory + 'Nm Per Step History.txt'


		;\\ Gain and exptime are only used when running in auto mode, and these values are supplied
		;\\ by the schedule file. In manual mode, the current values are used.
			self.gain = 0
			self.exptime = 0.1

		if data.recover eq 1 then begin
			;\\ Saved settings
				self.num_chords = restore_struc.num_chords
				self.start_volt_offset = restore_struc.start_volt_offset
				self.stop_volt_offset  = restore_struc.stop_volt_offset
				self.volt_step_size    = restore_struc.volt_step_size
				self.record_value 	   = restore_struc.record_value
				xoff = restore_struc.geometry.xoffset
				yoff = restore_struc.geometry.yoffset
		endif else begin
			;\\ Default settings
				self.num_chords = 5
				self.start_volt_offset = 1400
				self.stop_volt_offset  = 1600
				self.volt_step_size    = 10
				xoff = 0
				yoff = 0
		endelse


	base = widget_base(group_leader = data.leader, mbar = menu, xoff = xoff, yoff = yoff, $
					   title = 'SDI Steps Per Order', col=1)

	file_menu = widget_button(menu, value = 'File')

	font = 'TimesBold*16'
	font2 = 'TimesBold*16'


	drawbase = widget_base(base, col=2)
	draw = widget_draw(drawbase, xs=400, ys=300, uname = 'StepsPerOrder_'+self.obj_num+'_draw')
	draw2 = widget_draw(drawbase, xs=400, ys=300, uname = 'StepsPerOrder_'+self.obj_num+'_draw2')

	file_menu2 = widget_button(file_menu, value = 'Capture Image (.PNG)', uval = {tag:'image_capture', id:[draw], name:['StepsPerOrder'], type:'png'}, uname = 'Steps_'+self.obj_num+'_imgcappng')
	file_menu3 = widget_button(file_menu, value = 'Capture Image (.JPG)', uval = {tag:'image_capture', id:[draw], name:['StepsPerOrder'], type:'jpg'}, uname = 'Steps_'+self.obj_num+'_imgcapjpg')
	file_menu4 = widget_button(file_menu, value = 'Record Value in Text File', /checked_menu, uname = 'Steps_'+self.obj_num+'_recordval', uval = {tag:'Toggle_Record'})

	editbase = widget_base(base, col=2)

	leftbase = widget_base(editbase, col = 1)
	rightbase = widget_base(editbase, col = 1)

	b = widget_base(leftbase, col=2)
	voltlab1 = widget_label(b, value = 'Start Volt:', font=font, xs=100)
	start_volt = widget_text(b, /editable, value = string(self.start_volt_offset,f='(i0)'), uname = 'Steps_'+self.obj_num+'_startvolt', xs = 10)

	b = widget_base(leftbase, col=2)
	voltlab2 = widget_label(b, value = 'Stop  Volt:', font=font, xs=100)
	stop_volt  = widget_text(b, /editable, value = string(self.stop_volt_offset,f='(i0)'), uname = 'Steps_'+self.obj_num+'_stopvolt', xs = 10)

	b = widget_base(leftbase, col=2)
	voltlab3 = widget_label(b, value = 'Volt  Step:', font=font, xs=100)
	step_volt  = widget_text(b, /editable, value = string(self.volt_step_size, f='(f0)'), uname = 'Steps_'+self.obj_num+'_stepvolt', xs = 10)

	b = widget_base(rightbase, col=2)
	numslab3 = widget_label(b, value = '# of Scans:', font=font, xs=100)
	num_chords = widget_text(b, /editable, value = string(self.num_chords, f='(i0)'), uname = 'Steps_'+self.obj_num+'_numchords', xs = 10)

	b = widget_base(rightbase, col=2)
	wavelab  = widget_label(b, value = 'Wavelength:', font=font, xs=100)
	wavelength = widget_text(b, /editable, value = string(self.wavelength, f='(f0.1)'), uname = 'Steps_'+self.obj_num+'_wavelength', xs = 10)

	b = widget_base(rightbase, col=2)
	scanlab  = widget_label(b, value = 'Current Scan:', font=font, xs=100)
	curr_scan  = widget_text(b, value = string(self.curr_chord, f='(i0)'), uname = 'Steps_'+self.obj_num+'_currscan', xs = 10)

	b = widget_base(base, col=2)
	start_but = widget_button(b, value = 'Start Scan', uval = {tag:'start_scan'}, font = font)
	stop_but  = widget_button(b, value = 'Stop Scan', uval = {tag:'stop_scan'}, font=font)

	if self.record_value eq 1 then widget_control, file_menu4, set_button = 1

	self.id = base

	widget_control, base, /realize

	return, 1

end

;\D\<Toggle on/off the option to record steps/order values to a dedicated log file. This option is located>
;\D\<under the file menu of the plugin, and will be rememberd for this plugin.>
pro SDIStepsPerOrder::Toggle_Record, event  ;\A\<Widget event>

	if self.record_value eq 1 then begin
		self.record_value = 0
		widget_control, widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_recordval'), set_button = 0
	endif else begin
		self.record_value = 1
		widget_control, widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_recordval'), set_button = 1
	endelse

end

;\D\<Start scanning, set-up variables.>
pro SDIStepsPerOrder::start_scan, event  ;\A\<Widget event>

	if self.scanning ne 1 then begin

		;\\ Read in the user values
			start_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_startvolt')
			stop_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_stopvolt')
			step_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_stepvolt')
			num_chords_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_numchords')
			wavelength_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_wavelength')

			widget_control, get_value = start_volt_str, start_volt_id
			widget_control, get_value = stop_volt_str, stop_volt_id
			widget_control, get_value = step_volt_str, step_volt_id
			widget_control, get_value = num_chords_str, num_chords_id
			widget_control, get_value = wavelength_str, wavelength_id

			self.start_volt_offset = fix(start_volt_str)
			self.stop_volt_offset = fix(stop_volt_str)
			self.volt_step_size = float(step_volt_str)
			self.num_chords = fix(num_chords_str)
			self.wavelength = float(wavelength_str)

			w = self.wavelength
			while w eq 0.0 do begin
				if w eq 0.0 then begin
					xvaredit, w, name = 'Enter a wavelength in nanometres:', group=self.id
				endif
			endwhile
			self.wavelength = w
			widget_control, set_value = string(self.wavelength, f='(f0.1)'), wavelength_id

		;\\ Set up the arrays
			self.curr_chord = 0
			*self.image = uintarr(self.xdim, self.ydim, fix((self.stop_volt_offset - self.start_volt_offset)/self.volt_step_size))
    		*self.ref_image = uintarr(self.xdim, self.ydim)
    		*self.corr = fltarr(fix((self.stop_volt_offset - self.start_volt_offset)/self.volt_step_size), self.num_chords)
    		*self.chord_hist = fltarr(self.num_chords)


		;\\ Begin the scanner
			self.console -> scan_etalon, 'StepsPerOrder obj:' + self.obj_num, start_volt_offset = self.start_volt_offset, $
										  stop_volt_offset = self.stop_volt_offset, volt_step_size = self.volt_step_size, $
										  status = status, reference = reference, /start_scan, /get_ref

			if status eq 'Scanner started' then begin
				;\\ Store the reference image
					*self.ref_image = (reference - min(median(reference,3)))/100
				;\\ Set the scanning switch
					self.scanning = 1
				;\\ Update the log
					self.console -> log, 'Started a steps/order calculation @ ' + string(self.wavelength,f='(f0.1)')+'nm', 'StepsPerOrder'
					self.console -> log, 'Scan no: 1', 'StepsPerOrder'
			endif

	endif

end

;\D\<Auto-start called when running in auto-mode.>
function SDIStepsPerOrder::auto_start, args  ;\A\<String array of arguments from the schedule file>

	if n_elements(args) ne 5 then return, 'Error: wrong # of arguments'

	self.auto 				= 1
	self.start_volt_offset 	= float(args(1))
	self.stop_volt_offset  	= float(args(2))
	self.volt_step_size    	= float(args(3))
	self.wavelength			= float(args(0))
	self.num_chords			= float(args(4))
	self.gain				= float(args(5))
	self.exptime			= float(args(6))

	self.console -> cam_gain, 0, new_gain = self.gain
	self.console -> cam_exptime, 0, new_time = self.exptime

	;\\ Set the auto values
		start_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_startvolt')
		stop_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_stopvolt')
		step_volt_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_stepvolt')
		num_chords_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_numchords')
		wavelength_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_wavelength')

		widget_control, set_value = string(self.start_volt_offset,f='(i0)'), start_volt_id
		widget_control, set_value = string(self.stop_volt_offset,f='(i0)'),  stop_volt_id
		widget_control, set_value = string(self.volt_step_size,f='(f0)'),    step_volt_id
		widget_control, set_value = string(self.num_chords,f='(i0)'),        num_chords_id
		widget_control, set_value = string(self.wavelength,f='(f0.1)'),      wavelength_id

	;\\ Set up the arrays
		self.curr_chord = 0
		*self.image = fltarr(self.xdim, self.ydim, fix((self.stop_volt_offset - self.start_volt_offset)/self.volt_step_size))
    	*self.ref_image = fltarr(self.xdim, self.ydim)
       	*self.corr = fltarr(fix((self.stop_volt_offset - self.start_volt_offset)/self.volt_step_size), self.num_chords)
    	*self.chord_hist = fltarr(self.num_chords)

	;\\ Begin the scanner
		self.console -> scan_etalon, 'StepsPerOrder obj:' + self.obj_num, start_volt_offset = self.start_volt_offset, $
									  stop_volt_offset = self.stop_volt_offset, volt_step_size = self.volt_step_size, $
									  status = status, reference = reference, /start_scan, /get_ref

		if status eq 'Scanner started' then begin
			;\\ Store the reference image
				*self.ref_image = (reference - min(median(reference, 3)))/100.
			;\\ Set the scanning switch
				self.scanning = 1
			;\\ Update the log
				self.cnosole -> log, 'Auto-Started a steps/order calculation @ ' + string(self.wavelength,f='(f0.1)')+'nm', 'StepsPerOrder'
				self.console -> log, 'Scan no: 1', 'StepsPerOrder'
		endif else begin
			;\\ Update the log
				self.console -> log, 'Scanner could not be started - auto-mode', 'StepsPerOrder'
				return, 'Error: failed to start scanner'
		endelse

	return, 'Success'

end

;\D\<Process the latest camera frame: bascially calculate the correlation between the current>
;\D\<camera image and a reference image, store this value in a vector. If finished scanning,>
;\D\<fit the vector of correlation values to find the peak, and calculate the steps/order value>
;\D\<based on the position of that peak and the number of channels in a scan.>
pro SDIStepsPerOrder::frame_event, image, $     ;\A\<Latest camera image>
                                   channel      ;\A\<Current scan channel>

	scan = self.curr_chord

	if self.scanning eq 1 then begin

		curr_scan_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_currscan')
		widget_control, set_value = string(scan,f='(i0)'), curr_scan_id

		tv_id = widget_info(self.id, find_by_uname = 'StepsPerOrder_'+self.obj_num+'_draw')
		widget_control, get_value = draw_id, tv_id
		wset, draw_id

		currscan_id = widget_info(self.id, find_by_uname = 'Steps_'+self.obj_num+'_currscan')

		nsteps = fix((self.stop_volt_offset - self.start_volt_offset)/self.volt_step_size)

		if channel lt (nsteps) then begin


			!p.position = 0

			images = *self.image
			images(*,*,channel) = images(*,*,channel) + ((image - min(image))/100.)
			*self.image = images

			corr = *self.corr
			corr(channel, scan) = total(images(*,*,channel) * (*self.ref_image))/1e8
			*self.corr = corr

			xarr = (dindgen(nsteps))*self.volt_step_size + self.start_volt_offset

			if channel ge 1 then begin
			plot, xarr(0:channel-1), corr(0:channel-1, scan), yrange = [min(corr(0:channel-1, scan)), max(corr(0:channel-1, scan))], $
				  xrange = [xarr(0), xarr(channel-1)], xstyle = 1, color = self.palette.black, background = self.palette.white, /nodata, xtitle = 'Voltage', ytitle = 'Correlation'


			oplot, xarr(0:channel-1), corr(0:channel-1, scan), color = self.palette.black, thick = 2, psym=1
			endif
		endif

		if channel eq (nsteps - 1) then begin

			xarr = (dindgen(nsteps))*self.volt_step_size + self.start_volt_offset
			corr = double(*self.corr)

			fit_order = 3
			;fit = svdfit(xarr(2:*), corr(2:*,scan), 4, yfit = curve, /double)
			fit = poly_fit(xarr(2:*), corr(2:*,scan),fit_order, yfit = curve, /double)
			oplot, xarr(2:*), curve, color = self.palette.green, linestyle = 2, thick = 3

			dd = findgen(fit_order) + 1
			dd = dd * fit(1:*)
		 	dd = float(fz_roots(dd))
	    	ddy  = poly(dd, fit)
	    	best = where(ddy eq max(ddy))
			chord_hist = *self.chord_hist
	    	;chord_hist(scan) = (dd(best(0))*self.volt_step_size + self.start_volt_offset) / self.nchann
	    	chord_hist(scan) = dd(best(0))/self.nchann
	    	*self.chord_hist = chord_hist
            oplot, [dd(best(0)), dd(best(0))], [min(corr(*,scan)), max(corr(*,scan))], linestyle=5, color=self.palette.slate

			if scan lt (self.num_chords-1) then begin

				self.curr_chord = self.curr_chord + 1

				;\\ Restart the scanner
					self.console -> scan_etalon, 'StepsPerOrder obj:' + self.obj_num, start_volt_offset = self.start_volt_offset, $
										  stop_volt_offset = self.stop_volt_offset, volt_step_size = self.volt_step_size, $
										  status = status, reference = reference, /start_scan, /get_ref

				if status eq 'Scanner started' then begin
					;\\ Store the reference image
						ref = *self.ref_image
						;ref = ref + (reference/100.)
						ref = ref + ((reference - min(median(reference, 3)))/100.)
						*self.ref_image = ref
					;\\ Set the scanning switch
						self.scanning = 1
				endif

				this_chord = (dd(best(0))*self.volt_step_size + self.start_volt_offset) / self.nchann
				xyouts, /normal, .4, .4, 'Start Volt: ' + string(self.start_volt_offset, f = '(i0)'), color = self.palette.black
				xyouts, /normal, .4, .35, 'Stop  Volt: ' + string(self.stop_volt_offset, f = '(i0)'), color = self.palette.black
				xyouts, /normal, .4, .3, 'Step  Size: ' + string(self.volt_step_size, f = '(f0.3)'), color = self.palette.black
				xyouts, /normal, .4, .25, 'Steps/Channel: ' + string(this_chord, f = '(f0.3)'), color = self.palette.black

				tv_id = widget_info(self.id, find_by_uname = 'StepsPerOrder_'+self.obj_num+'_draw2')
				wait, 0.5
				widget_control, get_value = draw_id, tv_id
				wset, draw_id

				hist = *self.chord_hist
				plot, 1000*hist(0:scan)/self.wavelength, color=0, back = 255, /ystyle, ytit='1000 x SPO'
				oplot, 1000*hist(0:scan)/self.wavelength, color=self.palette.red, psym=1
				xyouts, /normal, .5, .2, 'Last: ' + string(hist(scan)/self.wavelength,f='(f0.5)'), col=self.palette.red

			endif else begin

				;\\ Turn off the scanning switch
					self.scanning = 0
					all_chords = *self.chord_hist
					chord = all_chords(n_elements(all_chords)-1)
					nm_per_step = chord / self.wavelength
					self.console -> set_nm_per_step, nm_per_step

				;\\ Save the console settings
					self.console -> save_current_settings

				;\\ Record the value in a text log if this option is set
					if self.record_value eq 1 then begin
						openw, fnum, self.record_file, /get_lun, /append
							printf, fnum, systime() + ' --> ' + string(nm_per_step,f='(f0.5)') + ' using lambda = ' + $
										  string(self.wavelength, f='(f0.1)') + ' nm'
						close, fnum
						free_lun, fnum
					endif

				;\\ If in auto mode, tell the console to end this plugin
					if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill

			endelse

		endif

	endif



NEXT_FRAME_EVENT:
end

;\D\<Stop the current scan, no steps/order value will be saved.>
pro SDIStepsPerOrder::stop_scan, event  ;\A\<Widget event>

	if self.scanning eq 1 then begin
		self.scanning = 0
		self.console -> scan_etalon, 'StepsPerOrder obj:' + self.obj_num, /stop_scan
	endif

	self.console -> log, 'StepsPerOrder stopped', 'StepsPerOrder'
	*self.corr = 0
	*self.image = 0
	*self.ref_image = 0
	*self.chord_hist = 0
	self.curr_chord = 0

	if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill

end

;\D\<Get settings to save.>
function SDIStepsPerOrder::get_settings

	struc = {id:self.id, num_chords:self.num_chords, start_volt_offset:self.start_volt_offset, stop_volt_offset:self.stop_volt_offset, $
			 volt_step_size:self.volt_step_size, geometry:self.geometry, need_timer:self.need_timer, need_frame:self.need_frame, $
			 record_value:self.record_value}

	return, struc

end

;\D\<Cleanup - free pointers, stop any active scan.>
pro SDIStepsPerOrder::cleanup, log  ;\A\<No Doc>

	ptr_free, self.corr, self.image, self.ref_image, self.chord_hist
	if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill
	if self.scanning eq 1 then begin
		self.scanning = 0
		self.console -> scan_etalon, 'StepsPerOrder obj:' + self.obj_num, /stop_scan
	endif

end

;\D\<The StepsPerOrder plugin is used to calculate the size of the `voltage' increment that>
;\D\<needs to be applied to each etalon leg at each channel in a scan such that a full scan>
;\D\<corresponds to a unit change in interference order.>
pro SDIStepsPerOrder__define

	void = {SDIStepsPerOrder, id:0L, $
							  corr:ptr_new(/alloc), $
							  num_chords:0, $
							  curr_chord:0, $
							  scanning:0, $
							  nchann:0, $
							  start_volt_offset:0, $
							  stop_volt_offset:0, $
							  volt_step_size:0.0, $
							  scan_obj:obj_new(), $
							  curr_chann:0, $
							  last_chann:0, $
							  image:ptr_new(/alloc), $
							  ref_image:ptr_new(/alloc), $
							  xdim:0, $
							  ydim:0, $
							  counter:0, $
							  last_counter:0, $
							  chord_hist:ptr_new(/alloc), $
							  wavelength:0.0, $
							  record_value:0, $
							  record_file:'', $
							  gain:0., $
							  exptime:0., $
							  inherits XDIBase}

end
