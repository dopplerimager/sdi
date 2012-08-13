;\\ Code formatted by DocGen


;\D\<Phasemapper initialization.>
function SDIPhaseMapper::init, restore_struc=restore_struc, $   ;\A\<Misc data>
                               data=data                        ;\A\<Restored settings>


	;\\ Generic Settings
		self.need_timer = 0
		self.need_frame = 1
		self.manager 	= data.manager
		self.console 	= data.console
		self.palette	= data.palette
		self.obj_num 	= string(data.count, format = '(i0)')

	;\\ Plugin Specific Settings
		self.nchann = data.nchann
		self.phasemap = ptr_new(/alloc)
		self.source_pmap = ptr_new(/alloc)
		self.image = ptr_new(/alloc)
		self.p = ptr_new(/allocate_heap)
		self.q = ptr_new(/allocate_heap)
		self.px = ptr_new(/allocate_heap)
		self.qx = ptr_new(/allocate_heap)
		self.xdim = data.xdim
		self.ydim = data.ydim




		;\\ Gain and exptime are only used when running in auto mode, and these values are supplied
		;\\ by the schedule file. In manual mode, the current values are used.
			self.gain = 0
			self.exptime = 0.1

		self.smooth_window = 0

		if data.recover eq 1 then begin
			;\\ Saved settings
				self.nscans = restore_struc.nscans
				self.source_order	   = restore_struc.source_order
				self.source_lambda	   = restore_struc.source_lambda
				self.smooth_window = 5
				xs 	= 512
				ys 	= 590
				xoff = restore_struc.geometry.xoffset
				yoff = restore_struc.geometry.yoffset
		endif else begin
			;\\ Default settings
				self.nscans = 3
				self.smooth_window = 5
				xoff = 0
				yoff = 0
				xs = 512
				ys = 590
		endelse


	base = widget_base(group_leader = data.leader, mbar = menu, xoff = xoff, yoff = yoff, $
					   title = 'SDI Phase Mapper', col=1)

	file_menu = widget_button(menu, value = 'File')
	self.id = base

	font = 'Ariel*Bold*18'
	draw = widget_draw(base, xs=256, ys=256, uname = 'Phase_'+self.obj_num+'_draw')

	file_menu1 = widget_button(file_menu, value = 'Set Interp Parameters', uval = {tag:'set_interp'})
	file_menu2 = widget_button(file_menu, value = 'Set Number of Scans', uval = {tag:'set_num_scans'})
	file_menu3 = widget_button(file_menu, value = 'Set Smooth Window', uval = {tag:'set_smooth_window'})
	file_menu4 = widget_button(file_menu, value = 'Capture Image (.PNG)', uval = {tag:'image_capture', id:[draw], name:['Phase Map'], type:'png'})
	file_menu5 = widget_button(file_menu, value = 'Capture Image (.JPG)', uval = {tag:'image_capture', id:[draw], name:['Phase Map'], type:'jpg'}, $
								uname = 'Phasemapper_'+self.obj_num+'_jpg')


	lab_base = widget_base(base, col=2)
	chann_box = widget_label(lab_base, value = 'Channel: '+string(self.channel,f='(i0)'), uname = 'Phase_'+self.obj_num+'_channel', font=font, xs=100)
	scan_box  = widget_label(lab_base, value = 'Scan: '+string(self.current_scan,f='(i0)'), uname = 'Phase_'+self.obj_num+'_scan', font=font, xs=100)

	but_base = widget_base(base, col=2)
	start_but = widget_button(but_base, value = 'Start Scan', uval = {tag:'start_scan'}, font=font)
	stop_but  = widget_button(but_base, value = 'Stop Scan',  uval = {tag:'stop_scan'},  font=font)

	widget_control, base, /realize

	return, 1

end

;\D\<When using more than one wavelength to generate a phasemap, we set the order of the cal sources>
;\D\<(the numbers corresponding to positions of the calibration source selector switch) and the>
;\D\<wavelengths those sources correspond to. The info from both phasemaps is store in such a way>
;\D\<as to allow the spectral plugin to interpolate between the phasemaps at the two wavelengths.>
pro SDIPhaseMapper::set_interp, event  ;\A\<Widget event>

	o = self.source_order
	xvaredit, o, name='Set Source Order', group = self.id
	self.source_order = o

	s = self.source_lambda
	xvaredit, s, name='Set Source Wavelengths (nm)', group = self.id
	self.source_lambda = s

end

;\D\<Set the width of the smoothing window, applied after phasemap is unwrapped.>
pro SDIPhaseMapper::set_smooth_window, event  ;\A\<Widget event>

	o = self.smooth_window
	xvaredit, o, name='Set Smooth Window', group = self.id
	self.smooth_window = o

end

;\D\<Set the number of scans to co-add.>
pro SDIPhaseMapper::set_num_scans, event  ;\A\<Widget event>

	o = self.nscans
	xvaredit, o, name='Set Number of Scans', group = self.id
	self.nscans = o

end

;\D\<Start scanning.>
pro SDIPhaseMapper::start_scan, event  ;\A\<Widget event>

	if self.scanning ne 1 then begin

		while self.source_lambda(0) eq 0.0 or self.source_lambda(1) eq 0.0 do begin
			s = self.source_lambda
			xvaredit, s, name='Cant Map Lambda = 0! Set New Source Wavelengths (nm)', group = self.id
			self.source_lambda = s
		endwhile

		*self.phasemap = intarr(self.xdim, self.ydim, self.nscans)
		*self.source_pmap = intarr(2, self.xdim, self.ydim)
		*self.image = uintarr(self.xdim, self.ydim, self.nchann)
		*self.p = fltarr(self.xdim, self.ydim)
		*self.q = fltarr(self.xdim, self.ydim)
		*self.px = fltarr(self.xdim, self.ydim)
		*self.qx = fltarr(self.xdim, self.ydim)
		self.current_source = 0


		;\\ Select the calibration source
		self.console -> mot_sel_cal, self.source_order(self.current_source)

		self.console -> scan_etalon, 'PhaseMapper obj:' + self.obj_num, /start_scan, status = status, $
								wavelength = self.source_lambda(self.current_source)

		if status eq 'Scanner started' then begin
			self.scanning = 1
			self.console -> log, 'Started phasemapping @ ' + string(self.source_lambda(self.current_source), f='(f0.1)') + 'nm', 'Phasemapper'
			self.console -> log, 'Source no: 1', 'Phasemapper'
		endif

	endif

end

;\D\<Auto start the Phasemapper - called whn running in auto mode, and plugin is started from a scheduled command.>
function SDIPhaseMapper::auto_start, args  ;\A\<String of arguments passed from the schedule file>

	if n_elements(args) ne 7 then return, 'Error: wrong # of arguments'

	;\\ Make sure shutter is open and mirror is selecting lasers
		self.console -> cam_shutteropen, 0
		self.console -> mot_drive_cal, 0

	self.auto = 1
	;self.wavelength = float(args(0))
	self.source_order(0) = args(0)
	self.source_order(1) = args(1)
	self.source_lambda(0) = float(args(2))
	self.source_lambda(1) = float(args(3))
	self.gain = float(args(4))
	self.exptime = float(args(5))
	self.smooth_window = float(args(6))

	*self.phasemap = intarr(self.xdim, self.ydim, self.nscans)
	*self.source_pmap = intarr(2, self.xdim, self.ydim)
	*self.image = uintarr(self.xdim, self.ydim, self.nchann)
	*self.p = fltarr(self.xdim, self.ydim)
	*self.q = fltarr(self.xdim, self.ydim)
	*self.px = fltarr(self.xdim, self.ydim)
	*self.qx = fltarr(self.xdim, self.ydim)
	self.current_source = 0

	self.console -> cam_gain, 0, new_gain = self.gain
	self.console -> cam_exptime, 0, new_time = self.exptime


	;\\ Select the calibration source
	self.console -> mot_sel_cal, self.source_order(self.current_source)

	self.console -> scan_etalon, 'PhaseMapper obj:' + self.obj_num, /start_scan, status = status, $
								 wavelength = self.source_lambda(self.current_source)


	if status eq 'Scanner started' then begin
		self.scanning = 1
		self.console -> log, 'Auto-Started phasemapping @ ' + string(self.source_lambda(self.current_source), f='(f0.1)'), 'Phasemapper'
		self.console -> log, 'Source no: 0', 'Phasemapper'
	endif else begin
		;\\ Update the log
			self.console -> log, 'Scanner could not be started - auto-mode', 'Phasemapper'
			return, 'Error: failed to start scanner'
	endelse

	return, 'Success'

end

;\D\<Frame event - update the Fourier summations for every pixel, if scan is finished,>
;\D\<finalize and unwrap the phasemap, and save it.>
pro SDIPhaseMapper::frame_event, image, $     ;\A\<Latest frame from the camera>
                                 channel      ;\A\<Current scan channel>


	scan = self.current_scan

	if self.scanning eq 1 then begin

		self.channel = channel

		;\\ Display properties and updates
			tv_id = widget_info(self.id, find_by_uname = 'Phase_'+self.obj_num+'_draw')
			chann_id = widget_info(self.id, find_by_uname = 'Phase_'+self.obj_num+'_channel')
			scan_id  = widget_info(self.id, find_by_uname = 'Phase_'+self.obj_num+'_scan')

			widget_control, get_value = draw_id, tv_id
			geom = widget_info(tv_id, /geom)
			wset, draw_id

			widget_control, set_value = 'Channel: '+string(channel, f='(i0)'), chann_id
			widget_control, set_value = 'Scan: '+string(scan+1, f='(i0)') + ' / ' + string(self.nscans, f='(i0)'), scan_id


		;\\ Store the latest image
			signal = double(image)
			signal -= min(signal)
			*self.px += (signal * sin((2*!pi*float(channel))/float(self.nchann)))
			*self.qx += (signal * cos((2*!pi*float(channel))/float(self.nchann)))

			signal = double(image)
			signal -= min(signal)
			signal = signal^1.
			*self.p += (signal * sin((2*!pi*float(channel))/float(self.nchann)))
			*self.q += (signal * cos((2*!pi*float(channel))/float(self.nchann)))


			tvlct, fltarr(256), fltarr(256), findgen(256)
			farr = congrid(bytscl(atan(*self.p, *self.q) / (2*!pi)), 256, 256)
			tv, farr



			load_pal, self.palette

		;\\ If last channel, make final array

			if channel eq (self.nchann-1) then begin

				farr = (atan(*self.p, *self.q) + !pi) / (2*!pi)
				farr = farr/max(farr)
				farr = farr * (self.nchann - 1)
				farr = fix(farr)

				tvlct, fltarr(256), fltarr(256), findgen(256)
				tv, bytscl(congrid(farr, 256, 256))

				farr_x = (atan(*self.px, *self.qx) + !pi) / (2*!pi)
				farr_x = farr_x/max(farr_x)
				farr_x = farr_x * (self.nchann - 1)
				farr_x = fix(farr_x)

				;window, 0, /free, xs = 512, ys = 512
				;tvlct, [intarr(128), 2*findgen(128)], intarr(256), [2*reverse(findgen(128)), intarr(128)]
				;tv, bytscl(farr_x - farr, min=-1, max=1)

				load_pal, self.palette
				path = self.console -> get_phase_map_path()
					base = self.console -> get_time_name_format()

				if scan eq (self.nscans-1) then begin

					*self.p = fltarr(self.xdim, self.ydim)
					*self.q = fltarr(self.xdim, self.ydim)
					*self.px = fltarr(self.xdim, self.ydim)
					*self.qx = fltarr(self.xdim, self.ydim)

					phase_map = farr

					;\\ Unwrap the phasemap
						threshold = 80
						radial_chunk = 50
						fxcen = 256
						fycen = 256
						phasemap = phasemap_unwrap(fxcen, fycen, radial_chunk, self.nchann, threshold, 0, phase_map, $
													/show, tv_id=draw_id, dims=[256, 256])
						phasemap = smooth(phasemap, self.smooth_window, /edge_truncate)

						map = *self.source_pmap
						map(self.current_source,*,*) = phasemap
						*self.source_pmap = fix(map)


					;\\ Show it
						loadct, 0, /silent
						wset, draw_id
						tvscl, congrid(phasemap, 256, 256)
						load_pal, self.palette



					;\\ Update all active spectrum plugins
					;	struc = self.manager -> generate_list()
					;	specs = where(strmid(strlowcase(struc.type),0,8) eq 'spectrum', nspecs)
					;	if nspecs gt 0 then begin
					;		failed = 0
					;		for n = 0, nspecs - 1 do struc.ref(specs(n)) -> set_phasemap, failed
					;	endif

					;\\ Refresh spectrum phasemaps (and zonemaps)
					;	self.console -> refresh_spec_pmaps

					;\\ If in auto mode, tell the console to end this plugin
					;	if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill

					;	self.scanning = 0


					;\\ If current_source is 0, then do source 1, else do the interpolation

					self.current_scan = 0

					if (self.current_source eq 0) and (self.source_lambda[0] ne self.source_lambda[1]) then begin

						self.current_source = self.current_source + 1
						if self.auto eq 1 then begin
							self.console -> cam_gain, 0, new_gain = self.gain
							self.console -> cam_exptime, 0, new_time = self.exptime
						endif

						self.console -> mot_sel_cal, self.source_order(self.current_source)

						self.console -> scan_etalon, 'PhaseMapper obj:' + self.obj_num, /start_scan, status = status, $
													  wavelength = self.source_lambda(self.current_source)

						if status eq 'Scanner started' then begin
							self.scanning = 1
							self.console -> log, 'Auto-Started phasemapping @ ' + string(self.wavelength, f='(f0.1)'), 'Phasemapper'
							self.console -> log, 'Source no: 1', 'Phasemapper'
						endif

					endif else begin

						l0 = self.source_lambda[0]
						l1 = self.source_lambda[1]

						pmaps = *self.source_pmap
						pmap0 = reform(pmaps[0,*,*])
						pmap1 = reform(pmaps[1,*,*])

						if (self.source_lambda[0] eq self.source_lambda[1]) then pmap1 = pmap0

						if l0 gt l1 then begin
							grad = (float(pmap0)/float(pmap1)) / (l1/l0)
							base = pmap1
							lambda = l1
						endif
						if l0 lt l1 then begin
							grad = (float(pmap1)/float(pmap0)) / (l0/l1)
							base = pmap0
							lambda = l0
						endif
						if l0 eq l1 then begin
						   grad = fltarr(n_elements(pmap0(*,0)),n_elements(pmap0(0,*))) + 1.
						   base = (pmap0+pmap1)/2
						   lambda = l0
						endif

						self.console -> set_phasemap, base, grad, lambda
						date_str = self.console -> get_time_name_format()

						;\\ Save the data
						save, filename = path + 'Phasemap ' + date_str + ' unwrapped.dat', base, grad, lambda

						self.console -> save_current_settings
						self.current_scan = 0
						self.scanning = 0

						if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill

					endelse

				endif else begin

					self.scanning = 0

					self.console -> scan_etalon, 'PhaseMapper obj:' + self.obj_num, /start_scan, status = status, $
												  wavelength = self.source_lambda(self.current_source)

					if status eq 'Scanner started' then begin
						self.scanning = 1
						self.current_scan = self.current_scan + 1
						self.console -> log, 'Scan no: ' + string(self.current_scan+1, f='(i0)'), 'Phasemapper'
					endif

				endelse




			endif

	endif

end

;\D\<Stop the current scan.>
pro SDIPhaseMapper::stop_scan, event  ;\A\<Widget event>

	if self.scanning eq 1 then begin
		self.scanning = 0
		self.console -> scan_etalon, 'Phasemapper obj:' + self.obj_num, /stop_scan


		self.console -> log, 'Phasemapper stopped', 'Phasemapper'
		self.current_scan = 0
		*self.phasemap = intarr(self.xdim, self.ydim, self.nscans)
		*self.image = uintarr(self.xdim, self.ydim, self.nchann)
		*self.p = fltarr(self.xdim, self.ydim)
		*self.q = fltarr(self.xdim, self.ydim)
		*self.px = fltarr(self.xdim, self.ydim)
		*self.qx = fltarr(self.xdim, self.ydim)

		if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill

	endif

end

;\D\<Get settings to save.>
function SDIPhaseMapper::get_settings

	struc = {id:self.id, $
			 nscans:self.nscans,  $
			 source_order:self.source_order, $
			 source_lambda:self.source_lambda, $
			 geometry:self.geometry, $
			 need_timer:self.need_timer, $
			 need_frame:self.need_frame}

	return, struc

end

;\D\<Cleanup, close any active scans.>
pro SDIPhaseMapper::cleanup, log  ;\A\<No Doc>

	ptr_free, self.image, self.phasemap, self.p, self.q, self.qx, self.px, self.source_pmap

	if self.auto eq 1 then self.console -> end_auto_object, self.id, self, /kill
	if self.scanning eq 1 then begin
		self.scanning = 0
		self.console -> scan_etalon, 'Phasemapper obj:' + self.obj_num, /stop_scan
	endif

end

;\D\<The Phasemapper plugin records `phase maps' which encode the scan channel at which>
;\D\<a spectrum recorded at the phasemap wavelength peaks for every pixel in the camera frame.>
pro SDIPhaseMapper__define

	void = {SDIPhaseMapper, id:0L, $
							nscans:0, $
							current_scan:0, $
							scanning:0, $
							nchann:0, $
							wavelength:0.0, $
							channel:0, $
							image:ptr_new(/alloc), $
							phasemap:ptr_new(/alloc), $
							xdim:0, $
							ydim:0, $
							p:ptr_new(/alloc), $
							q:ptr_new(/alloc), $
							px:ptr_new(/alloc), $
							qx:ptr_new(/alloc), $
							source_order:intarr(2), $
							source_lambda:fltarr(2), $
							source_pmap:ptr_new(/alloc), $
							current_source:0, $
							gain:0., $
							exptime:0., $
							smooth_window:0., $
							inherits XDIBase}

end
