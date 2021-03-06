;\\ Code formatted by DocGen


;\D\<Spectrum initializer, make sure we have a filename format and a zone map.>
function SDISpectrum::init, restore_struc=restore_struc, $         ;\A\<Restored settings>
                            data=data, $                           ;\A\<Misc data from the console>
                            zone_settings=zone_settings, $         ;\A\<A zone settings file name>
                            file_name_format=file_name_format      ;\A\<Format for generating the netcdf file name>

	;\\ Generic Settings
		self.need_timer = 0
		self.need_frame = 1
		self.manager 	= data.manager
		self.console 	= data.console
		self.palette	= data.palette
		self.obj_num 	= string(data.count, format = '(i0)')

	;\\ Do if no zone map settings
		if not keyword_Set(zone_settings) then begin
			zone_settings = 'default_zones.txt'
		endif

	;\\ Plugin Specific Settings
		self.nchann = data.nchann
		self.xdim = data.xdim
		self.ydim = data.ydim
		self.spectra = ptr_new(/alloc)
		self.last_spectra = ptr_new(/alloc)
		self.zonemap = ptr_new(/alloc)
		self.phasemap = ptr_new(/alloc)
		self.accumulated_image = ptr_new(/alloc)
		self.rads = ptr_new(/alloc)
		self.secs = ptr_new(/alloc)
		self.zone_centers = ptr_new(/alloc)
		self.zonemap_boundaries = ptr_new(/alloc)
		self.wavelength = data.wavelength
		self.dll = self.console -> get_dll_name()
		self.spec_path = self.console -> get_spectra_path()
		if strmid(zone_settings, strlen(zone_settings)-4, 4) ne '.txt' then zone_settings = zone_settings + '.txt'
		if keyword_set(file_name_format) then self.file_name_format = file_name_format
		self.zone_settings = self.console -> get_zone_set_path() + zone_settings

		self.console -> log, 'Spectrum INIT:', 'Spectrum'
		self.console -> log, '  Lambda = ' + string(data.wavelength, f='(f0.1)'), 'Spectrum'
		self.console -> log, '  Zonemap = ' + zone_settings, 'Spectrum'

		self.border = 20

		if data.recover eq 1 then begin
			;\\ Saved settings
				xoff = restore_struc.geometry.xoffset
				yoff = restore_struc.geometry.yoffset
		endif else begin
			;\\ Default settings
				xoff = 0
				yoff = 0
		endelse


	;\\ Build the widgets
		base = widget_base(group_leader = data.leader, mbar = menu, xoff = xoff, yoff = yoff, $
						   title = 'SDI Spectrum ' + string(self.wavelength, f='(f0.1)') + 'nm', col=1)

		file_menu = widget_button(menu, value = 'File')

		font = 'TimesBold*22'
		font2 = 'TimesBold*18'

		drawbase = widget_base(base, col=2)
		ldrawbase = widget_base(drawbase, col=1)
		draw = widget_draw(ldrawbase, xs=400, ys=400, uname = 'Spectrum_'+self.obj_num+'_draw', /align_center)

		rdrawbase = widget_base(drawbase, col=1)
		exp_draw = widget_draw(rdrawbase, xs=400, ys=200, uname='Spectrum_'+self.obj_num+'_exp_draw', /align_center)
		bck_draw = widget_draw(rdrawbase, xs=400, ys=200, uname='Spectrum_'+self.obj_num+'_bck_draw', /align_center)

		base_2 = widget_base(base, col = 1)
			chann_box = widget_label(base_2, value = 'Channel: ' + string(0, f='(i0)'), $
							uname = 'Spectrum_'+self.obj_num+'_channel', font=font2, xs = 300)

		base_3 = widget_base(base, col = 4)
		start_but = widget_button(base_3, value = 'Start Scan', uval = {tag:'start_scan'}, font = font)
		stop_but  = widget_button(base_3, value = 'Stop Scan', uval = {tag:'stop_scan'}, font=font)
		finalize_but  = widget_button(base_3, value = 'Finalize Exposure', uval = {tag:'finalize_scan'}, font=font)
		fit_but  = widget_button(base_3, value = 'Fit Spectra', uval = {tag:'fit_spectra'}, font=font)


		file_menu2 = widget_button(file_menu, value = 'Capture Image (.PNG)', $
								   uval = {tag:'image_capture', $
								   		   id:[draw, exp_draw], $
								   		   name:['Spectrum', 'Spectrum ExpMeter'], $
								   		   type:'png'})
		file_menu3 = widget_button(file_menu, value = 'Capture Image (.JPG)', $
								   uval = {tag:'image_capture', $
								   		   id:[draw, exp_draw], $
								   		   name:['Spectrum', 'Spectrum ExpMeter'], $
								   		   type:'jpg'})


		self.id = base


		widget_control, self.id, /realize

	;\\ Set the phasemap
		self -> set_phasemap, failed
		if failed eq 1 then return, 0

	;\\ Open/reopen a netcdf file to save spectra
		spec_save_info = self.console -> get_spec_save_info(self.nrings)
		header = self.console -> get_header_info()

		if self.file_name_format eq '' then begin
			file_name_format = ''
			file_name_format = inputbox(file_name_format, title = "Set Filename/Format String", group = self.id)
		endif

		get_jd0_sec, jd0, sec
		filename = dt_tm_mk(jd0, sec, f=file_name_format)
		filename = strupcase(header.site_code) + '_' + filename

		self.filename = filename

		spec_save_info.wavelength   = self.wavelength
		spec_save_info.phasemap 	= *self.phasemap
		spec_save_info.zone_radii   = *self.rads
		spec_save_info.zone_sectors = *self.secs

		if file_test(self.spec_path + filename) eq 1 then begin
			self.console -> log, 'Found existing data file, re-opening ' + self.spec_path + filename, 'Spectrum'
			Write_Spectra_NetCDF, 0, *self.spectra, 0, 0, 0, 0, fname=self.spec_path + filename, return_id=return_id, $
					  header=header, data=spec_save_info, /reopen
			self.file_id = return_id
		endif else begin
			self.console -> log, 'No data file exists, creating ' + self.spec_path + filename, 'Spectrum'
			Write_Spectra_NetCDF, 0, *self.spectra, 0, 0, 0, 0, /create, fname=self.spec_path + filename, return_id=return_id, $
					  header=header, data=spec_save_info
			self.file_id = return_id
		endelse


		return, 1

end

;\D\<Start scanning.>
pro SDISpectrum::start_scan, event  ;\A\<Widget event>

	if self.scanning ne 1 then begin

		w = self.wavelength
		while w eq 0.0 do begin
			if w eq 0.0 then begin
				xvaredit, w, name = 'Enter a wavelength in nanometres:', group=self.id
			endif
		endwhile
		self.wavelength = w

		;\\ Begin the scanner
			self.console -> scan_etalon, 'Spectrum (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
							status = status, wavelength=self.wavelength,  /start_scan

			if status eq 'Scanner started' then begin
				self.scanning = 1
				self.console -> log, 'Started acquiring spectra (manual mode)', 'Spectrum'
			endif

	endif

end

;\D\<Auto-start method, called when running in auto-mode.>
function SDISpectrum::auto_start, args  ;\A\<String array of arguments from the schedule file>

	if n_elements(args) ne 3 then return, 'Error: wrong # of arguments'

	self.auto = 1
	self.wavelength = float(args(0))


	;\\ Begin the scanner
		self.console -> scan_etalon, 'Spectrum (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						status = status, wavelength=self.wavelength,  /start_scan

		if status eq 'Scanner started' then begin
			self.scanning = 1
			self.console -> log, 'Started acquiring spectra (auto mode)', 'Spectrum'
		endif else begin
			;\\ Update the log
				self.console -> log, 'Scanner could not be started (auto mode)', 'Spectrum'
				return, 'Error: failed to start scanner'
		endelse

	return, 'Success'

end

;\D\<Initialize plugin variables, prepare the phase map, create a zone map.>
pro SDISpectrum::initializer


	;\\ Get the draw tv_id
		draw_id = widget_info(self.id, find_by_uname = 'Spectrum_'+self.obj_num+'_draw')
		widget_control, get_value = tv_id, draw_id


	;\\ Wrap the phasemap
		phasemap = *self.phasemap
		phasemap = phasemap mod self.nchann
		*self.phasemap = phasemap
		self.console -> log, 'Wrapped the phasemap', 'Spectrum'


	;\\ Make a zonemap
		READ_ZONE_SETTINGS:
		a=''
		b=''

		openr, file, self.zone_settings, /get_lun
			readf, file, a
			readf, file, b
		close, file
		free_lun, file

		resa = execute(a)
		resb = execute(b)

		if resa eq 0 or resb eq 0 then begin
			self.console -> log, 'Zonemap settings file caused an error: reverting to default_zones.txt', 'Spectrum'
			self.zone_settings = self -> get_zone_set_path() + 'default_zones.txt'
			goto, READ_ZONE_SETTINGS
		endif else begin
			self.console -> log, 'Zonemap file read successfully', 'Spectrum'
		endelse

		*self.rads = rads
		*self.secs = secs

	;\\ Get some console data
		self.nrings = n_elements(rads)
		spec_save_info = self.console -> get_spec_save_info(self.nrings)
		header = self.console -> get_header_info()


		cent = [spec_save_info.x_center, spec_save_info.y_center]

		nums = intarr(n_elements(secs))
		nums(0) = 0
		for n = 1, n_elements(secs) - 1 do begin
			nums(n) = total(secs(0:n-1))
		endfor

		zonemap = zonemapper(self.xdim, self.ydim, cent, rads, secs, nums)
		*self.zonemap = zonemap
		self.nzones = max(zonemap) + 1

		self.console -> log, 'Zone settings:', 'Spectrum'
		self.console -> log, 'Rads - ' + string(rads, f='("[",'+string(n_elements(rads),f='(i0)')+'(f0.2," "),"]")'), 'Spectrum'
		self.console -> log, 'Secs - ' + string(secs, f='("[",'+string(n_elements(secs),f='(i0)')+'(i0,  " "),"]")'), 'Spectrum'
		self.console -> log, 'Nums - ' + string(nums, f='("[",'+string(n_elements(nums),f='(i0)')+'(i0,  " "),"]")'), 'Spectrum'

	;\\ Display the zonemap
		drawID = widget_info(self.id, find_by_uname = 'Spectrum_'+self.obj_num+'_draw')
		geom = widget_info(drawID, /geometry)

		xsize = geom.xsize - self.border*2
		ysize = geom.ysize - self.border*2
		zonemap = congrid(zonemap, xsize, ysize)

		wset, tv_id
		loadct, 31, /silent
		tvscl, zonemap, self.border, self.border
		load_pal, self.palette

	;\\ Get the x,y positions of the zone centers for plotting
		zone_centers = intarr(self.nzones, 2)
		for zn = 0, self.nzones-1 do begin
			pts = where(zonemap eq zn, npts)
			ind = array_indices(zonemap, pts)
			zone_centers(zn,0) = (max(ind(0,*))+min(ind(0,*)))/2
			zone_centers(zn,1) = (max(ind(1,*))+min(ind(1,*)))/2
			xyouts, zone_centers(zn,0) + self.border, $
					zone_centers(zn,1) + self.border, $
					string(zn,f='(i0)'), /device, color=self.palette.black, align=.5
		endfor
		*self.zone_centers = zone_centers


	;\\ Get an array containing the indexes of the boundaries between zone cells

		zbounds = intarr(xsize, ysize)

		for x = 0, xsize - 2 do begin
		for y = 0, ysize - 1 do begin
			if (zonemap(x,y) - zonemap(x+1,y)) ne 0 then zbounds(x,y) = 1
		endfor
		endfor

		for x = 0, xsize - 1 do begin
		for y = 0, ysize - 2 do begin
			if (zonemap(x,y) - zonemap(x,y+1)) ne 0 then zbounds(x,y) = 1
		endfor
		endfor

		*self.zonemap_boundaries = zbounds

	;\\ Set up the spectra array
		*self.spectra = ulonarr(self.nzones, self.nchann)
end

;\D\<Frame event where the spectral information from the latest camera image is extracted. The primary>
;\D\<purpose of this function is to call "uUpdateSpectra" in the SDI\_External dll, which updates the>
;\D\<current spectral information based on the latest camera frame. This function also checks to see>
;\D\<if exposures are finished, sends real-time data snapshots to the console for ftp-ing, accumulates>
;\D\<the background `allsky' image, and updates the display of spectra and signal/noise history.>
pro SDISpectrum::frame_event, image, $     ;\A\<Latest camera image>
                              channel      ;\A\<Current scan channel>
common spec_save, spec, zone, phase, acc_im

	now = systime(1)
	;\\ Get the draw tv_id
		chan_id = widget_info(self.id, find_by_uname = 'Spectrum_'+self.obj_num+'_channel')
		draw_id = widget_info(self.id, find_by_uname = 'Spectrum_'+self.obj_num+'_draw')
		widget_control, get_value = tv_id, draw_id

		widget_control, set_value = 'Channel: '+string(channel+1,f='(i0)'), chan_id

	if n_elements(acc_im) eq 0 then begin
	 		spec = *self.spectra
			zone = *self.zonemap
			phase = *self.phasemap
			*self.accumulated_image = ulonarr(self.xdim, self.ydim)
			acc_im = *self.accumulated_image
	endif

	if self.scanning eq 1 then begin

		nsteps = self.nchann

		if channel eq 0 and self.nscans eq 0 then begin
			self.scan_start_time = dt_tm_tojs(systime(/ut))
			;\\ Reset the accumulated image array
			*self.accumulated_image = ulonarr(self.xdim, self.ydim)
			;\\ Reset the signal noise history array
			self.signal_noise_history[*] = 0
			self.scan_background_history[*] = 0
	 		spec = *self.spectra
			zone = *self.zonemap
			phase = *self.phasemap
			acc_im = *self.accumulated_image
		endif

		self.channel_background_history[channel] = min(smooth(image, 40, /edge))

		acc_im = acc_im + image
		sizes = fix([self.xdim, self.ydim, self.nzones, self.nchann])
		;stop ;###########################
		res = call_external(self.dll, 'uUpdateSpectra', long(image), fix(phase), zone, spec, fix(channel), sizes, value=bytarr(6))

;print, 'Done for spex processing: ', systime(1) - now
		;print, 'Reached spex 1:', systime()
		if channel eq (nsteps-1) then begin

			self.nscans = self.nscans + 1
			*self.accumulated_image = acc_im
			*self.spectra = spec


			;\\ Check for sufficient signal (exposure time) and generate a signal/noise estimate
				signal = 0UL
				bgnd   = 0UL
				zone_power = fltarr(self.nzones)
				signal_noise = fltarr(self.nzones)
				for z = 0, self.nzones-1 do begin
				    this_sig = spec(z,*) ;- min(spec(z,*))
				    noise = n_elements(this_sig)*min(smooth(this_sig,7))
				    bgnd  = bgnd + noise
				    signal = signal + total(this_sig) - noise
				    ;print, "this sig", total(this_sig), "min was", min(spec(z,*))
					;signal = signal + total(spec(z,*)); - min(smooth(spec(z,*),5)))
					power = (abs(fft(this_sig)))^2
					signal_noise(z) = power(1)/median(power((self.nchann*3./8.):self.nchann/2.))
					zone_power[z] = power[1]
				endfor

			;\\ Update the signal_noise_history array
				ave_signal_noise = median(signal_noise)
				if finite(ave_signal_noise) eq 0 then ave_signal_noise = abs(100*randomn(blahblah))
				min_signal_noise = min(signal_noise)

				last_history = where(self.signal_noise_history eq 0)
				if n_elements(last_history) eq 1 then last_history = -1 else last_history = last_history[0]
				self.signal_noise_history[last_history] = ave_signal_noise
				self.scan_background_history[self.nscans - 1] = stddev(self.channel_background_history[0:self.nchann-1])

			;\\ If doing green, update the snr/scan value in the console
				if self.wavelength eq 557.7 then begin
					self.console->set_snr_per_scan, ave_signal_noise/float(self.nscans)
				endif

				time_elapsed = (dt_tm_tojs(systime(/ut)) - self.scan_start_time)
				signal = (signal / time_elapsed)/n_elements(image)
				bgnd = (bgnd / time_elapsed)/n_elements(image)

			;\\ Set exposure finished conditions - min 2 scans, etc.
				exp_finished = 0
				if self.nscans ge 2 and (min_signal_noise ge 1000 or ave_signal_noise ge 1500) then exp_finished = 1
				if time_elapsed gt 600 then exp_finished = 1
				if (min_signal_noise gt 15000) and (self.nscans ge 2) then exp_finished = 1

			;\\ Lasers only need the one scan however
				if self.wavelength eq 543.5 or self.wavelength eq 632.8 then begin
					if self.nscans gt 0 and ave_signal_noise lt 1500 and self.auto eq 1 then begin
				       self.scanning = 0
				       self.console->shutdown_spex
				       cmd = 'start "Restarting Observations" "c:\users\sdi3000\sdi\watchdog\restart_sdi3000_obs.bat" '
				       spawn, cmd
				    endif
					if self.nscans ge 1 and ave_signal_noise ge 50000 then exp_finished = 1
				endif

			;\\ If the finalize flag is set, end the exposure
				if self.finalize_flag eq 1 then exp_finished = 1

				load_pal, self.palette

			;\\ Plot snr history
				!p.multi=0
				!p.position=0
				exp_win_val = widget_info(self.id, find_by_uname='Spectrum_'+self.obj_num+'_exp_draw')
				widget_control, get_value=exp_win_id, exp_win_val
				wset, exp_win_id

				colors = intarr(last_history+1)
				colors(*) = self.palette.white

				if last_history ge 0 then begin

					snrHWidth = .45
					snrMax = max(self.signal_noise_history)
					plot, [-.9, (last_history > 10) + .9], [0,0], /nodata, col = self.palette.white, $
						  yrange = [0, snrMax], /xstyle, $
						  title = 'Signal/Noise History', xtitle = 'Scan #', ytitle = 'Signal/Noise', $
						  xtickint=1, pos=[.1, .18, .98, .91]

					for snrIdx = 0, last_history do begin
						polyfill, snrIdx + [-snrHWidth, -snrHWidth, snrHWidth, snrHWidth], $
								  [0, self.signal_noise_history[snrIdx], self.signal_noise_history[snrIdx], 0], /data
					endfor
				endif





			;\\ Plot background history
				bck_win_val = widget_info(self.id, find_by_uname='Spectrum_'+self.obj_num+'_bck_draw')
				widget_control, get_value=bck_win_id, bck_win_val
				wset, bck_win_id
				plot, self.scan_background_history[0:self.nscans - 1], xtickint=1, xtitle='Scan #', ytitle='Sttdev Bckgrnd / Power'


			!p.multi = [0,1,self.nzones]
			zcs = *self.zone_centers

			acc_im = *self.accumulated_image
			zon_bn = *self.zonemap_boundaries

			acc_im = bytscl(acc_im)



			drawID = widget_info(self.id, find_by_uname = 'Spectrum_'+self.obj_num+'_draw')
			geom = widget_info(drawID, /geometry)

			wset, tv_id
			loadct, 0, /silent
			erase, 0

			xsize = geom.xsize - 2*self.border
			ysize = geom.ysize - 2*self.border

			imord = sort(acc_im)
			minb = acc_im(imord(0.1*n_elements(imord)))
			maxb = acc_im(imord(0.9*n_elements(imord)))
			displayImage = self.palette.imgmin + bytscl(acc_im, min=minb, max=maxb, top=self.palette.imgmax - self.palette.imgmin-1)
			displayImage = congrid(displayImage, xsize, ysize)
			displayImage(where(zon_bn eq 1)) = 255
			tv, displayImage, self.border, self.border
			load_pal, self.palette

			case self.wavelength of

				630.0 : color = self.palette.red
				632.8 : color = self.palette.yellow
				543.5 : color = self.palette.yellow
				557.7 : color = self.palette.green
				589.0 : color = self.palette.orange
				732.0 : color = self.palette.rose

				else : color = self.palette.white

			endcase

			sumspec = median(total(spec, 1), 3)
			pk = where(sumspec eq max(sumspec))
			pk = pk(0)
			!p.noerase = 1
			for c = 0, self.nzones-1 do begin
				xc = zcs(c,0)
				yc = zcs(c,1)
				!p.position = [xc-20,yc-20,xc+20,yc+20] + self.border
				plot,  shift(spec(c,*)-min(spec(c,*)), nsteps/2 - pk), color = self.palette.white, xstyle=9, ystyle=4, thick=3, /device, /nodata, xtickname=strarr(10)+' '
				oplot, shift(spec(c,*)-min(spec(c,*)), nsteps/2 - pk), color = color, thick=6, psym = 3, symsize = 20
			endfor
			!p.noerase = 0
			!p.multi = 0


			js2ymds, self.scan_start_time, y, m, d, s
			hours = s /3600.
			mins = (hours mod 1) * 60.
			secs = (mins mod 1) * 60.
			time_str = string(hours, f='(i0)') + ':' + string(mins, f='(i0)') + ':' + string(secs, f='(i0)')

			!p.font = 0
			device, set_font = 'Ariel*Bold*16'

			xyouts, /normal, .01, .96, 'Start: ' + time_str, color=self.palette.white
			xyouts, /normal, .99, .96, 'Exposure: ' + strcompress(string(time_elapsed/60., format='(f4.1)'), /remove_all) + ' min', align=1
			xyouts, /normal, .01, .05, 'Scans: ' + strcompress(string(self.nscans,f='(i0)'), /remove), color=self.palette.white
			xyouts, /normal, .01, .01, 'Median SNR: ' + strcompress(string(ave_signal_noise,f='(i10)'), /remove), color=self.palette.white
			xyouts, /normal, .99, .01, 'Brite: ' + strcompress(string(signal, format='(f10.1)'), /remove), color=self.palette.white, align=1.
			xyouts, /normal, .99, .05, 'Bgnd: ' + strcompress(string(bgnd, format='(f10.1)'), /remove), color=self.palette.white, align=1.
			xyouts, /normal, .50, .96, '!5S!3', charsize = 1.5, charthick = 2, color=self.palette.white, align=0.5
			xyouts, /normal, .50, .01, '!5N!3', charsize = 1.5, charthick = 2, color=self.palette.white, align=0.5
			xyouts, /normal, .02, .50, '!5W!3', charsize = 1.5, charthick = 2, color=self.palette.white, align=0.5
			xyouts, /normal, .98, .50, '!5E!3', charsize = 1.5, charthick = 2, color=self.palette.white, align=0.5

			!p.font = -1


			if exp_finished eq 1 then begin

				spec_save_info = self.console -> get_spec_save_info(self.nrings)
				ncdf_close, self.file_id
				free_lun, self.file_id
				end_time = dt_tm_tojs(systime(/ut))
				Write_Spectra_NetCDF, self.file_id, *self.spectra, self.scan_start_time, end_time, $
									  self.nscans, *self.accumulated_image, data=spec_save_info, $
									  fname=self.spec_path + self.filename, return_id=return_id, /update


				;\\ Send a snapshot of the latest spectra to the console
					snapshot = {spectra:*self.spectra, $
								start_time:self.scan_start_time, $
								end_time:end_time, $
								scans:self.nscans, $
								rads:*self.rads, $
								secs:*self.secs, $
								wavelength:self.wavelength * 10, $
								scan_channels:self.nchann, $
								nzones:self.nzones }
					self.console -> spectrum_snapshot, snapshot


				;\\ Clear some fields ready for next acquisition
					self.file_id = return_id
					self.finalize_flag = 0
					self.scanning = 0
					self.nscans   = 0
					*self.last_spectra = *self.spectra
					*self.spectra = ulonarr(self.nzones, self.nchann)


				;\\ If in auto mode, get the console to remove us as the active plugin
					if self.auto eq 1 then self.console -> end_auto_object, self.id, self

			endif else begin

				;\\ Restart the scanner
					self.console -> scan_etalon, 'Spectrum obj:'+self.obj_num, status = status, $
					     			wavelength=self.wavelength,  /start_scan
					self.scanning = 1
			endelse


		endif


	endif

EXIT_FRAME_PROCESSING:
end

;\D\<Stop a currently active scan.>
pro SDISpectrum::stop_scan, event  ;\A\<Widget event>

	if self.scanning eq 1 then begin
		self.scanning = 0
		self.console -> scan_etalon, 'Spectrum (' + string(self.wavelength, f='(f0.1)') + ') obj:' + self.obj_num, $
						/stop_scan

		self.console -> log, 'Spectrum stopped', 'Spectrum'

		self.finalize_flag = 0
		self.scanning = 0
		self.nscans   = 0
		*self.last_spectra = *self.spectra
		*self.spectra = ulonarr(self.nzones, self.nchann)

		if self.auto eq 1 then self.console -> end_auto_object, self.id, self

	endif

end

;\D\<Called when a user clicks on the "Finalize" button, to indicate that an exposure should be>
;\D\<finished after the next scan, regardless of signal-to-noise, etc.>
pro SDISpectrum::finalize_scan, event  ;\A\<Widget event>
	self.finalize_flag = 1
end

;\D\<Set-up the phasemap, that is, retrieve phase map parameters from the console, interpolate>
;\D\<to the spectrum wavelength, and wrap the phase map.>
pro SDISpectrum::set_phasemap, failed  ;\A\<OUT: flag to indicate failure, not currently used (returns 0)>

	failed = 0

	self.console -> log, 'Setting phasemap', 'Spectrum'

	*self.phasemap = intarr(self.xdim, self.ydim)

	;\\ Get the phasemap if it exists in the console
		self.console -> get_phasemap, base, grad, lambda

	;\\ Interpolate to self.wavelength
		;phmap = float(base) + (float(grad) * (self.wavelength - lambda))
		phmap = float(base) * (lambda/self.wavelength) * grad
		*self.phasemap = fix(phmap)

		pmap = *self.phasemap
		wavelength = self.wavelength

		save, filename = 'c:\one.dat', pmap, base, grad, lambda, wavelength

		self -> initializer

end

;\D\<Fit spectra and create skymaps of peak position and temperature, and display them. This function>
;\D\<was introduced to diagnose Mawson camera problems, and has stuck around since it may be generally>
;\D\<useful.>
pro SDISpectrum::fit_spectra, event  ;\A\<Widget event>

	;\\ Get instrument profiles
	if self.insprof_filename eq '' then begin
		ipfile = dialog_pickfile(path=self.console->get_spectra_path(), title = 'Select Calibration Spectra')
		if ipfile ne '' then begin
			self.insprof_filename = ipfile
		endif else begin
			return
		endelse
	endif

	sdi3k_read_netcdf_data, self.insprof_filename, meta=ip_meta, spex=ip_spex, /close


	;\\ Insprof background subtraction and normalization
		ip_spex = ip_spex[0].spectra
		spec0 = reform(ip_spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(ip_meta.scan_channels)/float(ip_meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(ip_meta.scan_channels)/float(ip_meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(ip_meta.scan_channels)
		spec_shift = ip_meta.scan_channels/2. - c

    	for zidx = 0, ip_meta.nzones - 1 do begin
    		ip_spex[zidx, *] = ip_spex[zidx,*] - min(mc_im_sm(ip_spex[zidx,*], 7))
    		ip_spex[zidx, *] = shift(ip_spex[zidx, *], spec_shift)
        	insprof = fft(reform(ip_spex[zidx,*]), -1)
        	nrm = abs(insprof[1]) ;###
        	ip_spex[zidx,*] = ip_spex[zidx,*]/(nrm)
	    endfor


	if self.etalon_gap eq 0.0 then begin
		gap = self.etalon_gap
		xvaredit, gap, name='Etalon Gap (mm)', group=self.id
		self.etalon_gap = gap
	endif

	meta = {wavelength_nm:self.wavelength, $
			scan_channels:self.nchann, $
			gap_mm:self.etalon_gap, $
			nzones:self.nzones}

	spex = *self.last_spectra


	;\\ Crude zone 0 peak position
		spec0 = reform(spex[0,*])
		p = total(spec0 * sin((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		q = total(spec0 * cos((2*!pi*findgen(meta.scan_channels)/float(meta.scan_channels))))
		c = (atan(p, q) / (2*!pi))*float(meta.scan_channels)
		spec_shift = meta.scan_channels/2. - c

	;\\ Fit
		rec = 0
		ssec = self.scan_start_time
    	esec = ssec + 10
    	itmp = 700.
    	sdi3k_level1_fit, rec, (ssec + esec)/2, spex, meta, sig2noise, chi_squared, $
    	          		  sigarea, sigwid, sigpos, sigbgnd, backgrounds, areas, widths, positions, $
    	           		  ip_spex, initial_temp=itmp, min_iters=15, shiftpos = spec_shift

		positions = (positions + 2.25*meta.scan_channels) mod meta.scan_channels


	cnv = 3.e8*meta.wavelength_nm*1e-9/(2.*meta.gap_mm*1e-3*meta.scan_channels)

	window, /free, xs = 1000, ys = 600, title = 'Fitted Values'
	p = positions*cnv
	p -= p[0]
	srt = p[sort(p)]
	scl = [srt[n_elements(srt)*.02], srt[n_elements(srt)*.98]]
	scl = [-100,200]
	p = bytscl(p, min=scl[0], max=scl[1], top=254)

	red = [intarr(128), indgen(128)]
	gre = [intarr(256)]
	blu = [reverse(indgen(128)), intarr(128)]
	tvlct, red, gre, blu
	loadct, 39, /silent
	plot_zone_bounds, 500, *self.rads, *self.secs, fill = p, offset=[0, 100]
	scl_bar = fltarr(100, 20)
	for j = 0, 19 do scl_bar[*, j] = interpol([0,255], [0,99], findgen(100) )
	tv, scl_bar, 200, 30, /device
	plot_zone_bounds, 500, *self.rads, *self.secs, color=150, offset=[0, 100], ctable=0
	loadct, 39, /silent
	xyouts, /device, 200, 30, string(scl[0], f='(f0.1)'), color=255, align=1.1
	xyouts, /device, 300, 30, string(scl[1], f='(f0.1)'), color=255, align=-.1
	xyouts, /device, 250, 10, 'Velocity', color=255, align=.5

	p = widths
	scl = [500, 2000]
	p = bytscl(p, min=scl[0], max=scl[1], top=254)
	plot_zone_bounds, 500, *self.rads, *self.secs, fill = p, offset=[500, 100], ctable=39
	plot_zone_bounds, 500, *self.rads, *self.secs, color=150, offset=[500, 100], ctable=0
	loadct, 39, /silent
	tv, scl_bar, 700, 30, /device
	xyouts, /device, 700, 30, string(scl[0], f='(f0.1)'), color=255, align=1.1
	xyouts, /device, 800, 30, string(scl[1], f='(f0.1)'), color=255, align=-.1
	xyouts, /device, 750, 10, 'Temperature', color=255, align=.5


	window, /free, xs = 1000, ys = 600, title = 'Peaks'
	!p.multi = 0
	!p.position = 0
	plot, (positions - positions[0])*cnv
end

;\D\<Get settings to save.>
function SDISpectrum::get_settings

	struc = {id:self.id, geometry:self.geometry, need_timer:self.need_timer, need_frame:self.need_frame}

	return, struc

end

;\D\<Cleanup - stop any active scans, close the netcdf file, free pointers.>
pro SDISpectrum::cleanup, log  ;\A\<No Doc>

	if self.scanning eq 1 then self -> stop_scan, 0
	ptr_free, self.spectra, self.zonemap, self.phasemap, self.zone_centers
	ncdf_close, self.file_id

end

;\D\<The Spectrum plugin acquires spectra and saves them to netcdf files. It requires a wavelength, a filename>
;\D\<to save to and a zonemap file to use for dividing up the field of view. Some things are hard coded in this>
;\D\<which should probably be made configurable (see the frame\_event method). After each complete exposure, this>
;\D\<plugin will attempt to send back a snapshot of the most recent acquisition to an ftp server for real-time>
;\D\<data processing (the snapshot is sent back if the logging.ftp\_snapshot field is populated in the settings file,>
;\D\<see XDIConsole::spectrum\_snapshot for the details of this).>
pro SDISpectrum__define

	void = {SDISpectrum, id:0L, $
						 scanning:0, $
						 nchann:0, $
						 xdim:0, $
						 ydim:0, $
						 save_file_id:0, $
						 spectra:ptr_new(/alloc), $
						 last_spectra:ptr_new(/alloc), $
						 zonemap:ptr_new(/alloc), $
						 zonemap_boundaries:ptr_new(/alloc), $
						 phasemap:ptr_new(/alloc), $
						 signal_noise_history:fltarr(100), $
						 channel_background_history:fltarr(200), $
						 scan_background_history:fltarr(100), $
						 zone_centers:ptr_new(/alloc), $
						 nzones:0, $
						 dll:'', $
						 border:0, $
						 nscans:0, $
						 file_id:0, $
						 zone_settings:'', $
						 wavelength:0.0, $
						 scan_start_time:0D, $
						 spec_path:'', $
						 nrings:0, $
						 file_name_format:'', $
						 filename:'', $
						 rads:ptr_new(/alloc), $
						 secs:ptr_new(/alloc), $
						 accumulated_image:ptr_new(/alloc), $
						 finalize_flag:0, $
						 insprof_filename:'', $
						 etalon_gap:0.0, $
						 inherits XDIBase}


end
