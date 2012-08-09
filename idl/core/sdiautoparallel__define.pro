
function SDIAutoParallel::init, data=data, restore_struc = restore_struc

	self.palette = data.palette
	self.need_timer = 0
	self.need_frame = 1
	self.obj_num = string(data.count, format = '(i0)')
	self.manager = data.manager
	self.console = data.console

	xdim = data.xdim
	ydim = data.ydim
	self.ref_image = ptr_new(/alloc)

	*self.ref_image = ulonarr(xdim, ydim)

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
					   title = 'AutoParallel_', group_leader = leader)

	start_but = widget_button(base, xo = 10, yo = 10, value = 'Start', uval = {tag:'start_parallel'}, font = font, $
							  uname = 'AutoParallel_'+self.obj_num+'_start', xs = 100)

	stop_but = widget_button(base, xo = 250, yo = 10, value = 'Stop', uval = {tag:'stop_parallel'}, font = font, $
							  uname = 'AutoParallel_'+self.obj_num+'_stop', xs = 100)

	leg1_lab = widget_text(base, xo = 10, yo = 50, value = 'Leg 1: ', font=font, uname='AutoParallel_'+self.obj_num+'leg1')
	leg2_lab = widget_text(base, xo = 10, yo = 90, value = 'Leg 2: ', font=font, uname='AutoParallel_'+self.obj_num+'leg2')
	leg3_lab = widget_text(base, xo = 10, yo = 130, value = 'Leg 3: ', font=font, uname='AutoParallel_'+self.obj_num+'leg3')
	step_lab = widget_text(base, xo = 10, yo = 170, value = 'Step: ', $
						   uname = 'AutoParallel_'+self.obj_num+'step', font=font)

	self.id = base

	widget_control, base, /realize

	return, 1

end


pro SDIAutoParallel::start_parallel, event

	if self.status ne 'searching' then begin

		self.param(*) = 0.0

		self.curr_leg = 1
		self.step = 10
		self.param_pos = 0

		self.status = 'searching'

		self.get_ref_flag = 1

	endif

end


pro SDIAutoParallel::stop_parallel, event

	self.status = 'idle'

end


pro SDIAutoParallel::frame_event, image, channel

	if self.status eq 'searching' then begin

		if self.get_ref_flag eq 1 then begin
			self.get_ref_flag = 0
			*self.ref_image = image
			goto, END_PARALLEL_FRAME_EVENT
		endif

		if self.param_pos eq 10 then begin
			self.param_pos = 0

			;\\ Find the best value in the param array, and the leg_value where it occurs
			peak_pos = where(self.param eq max(self.param))
			peak_leg = self.nominal - self.step*(peak_pos - 4)

			window, 11
			plot, self.param, /ystyle

			loadct, 0

			window, 12
			tvscl, *self.ref_image

			if self.curr_leg eq 1 then self.leg1 = peak_leg
			if self.curr_leg eq 2 then self.leg2 = peak_leg
			if self.curr_leg eq 3 then self.leg3 = peak_leg

			if peak_pos eq 0 or peak_pos eq 8 then begin
				self.param(*) = 0
				goto, END_PARALLEL_FRAME_EVENT
			endif else begin
				self.param(*) = 0.0
				if self.curr_leg lt 3 then begin
					self.curr_leg = self.curr_leg + 1
				endif else begin
					self.curr_leg = 1
					if self.step gt 2 then begin
						self.step = self.step - 2
					endif else begin
						self.status = 'idle'
						goto, END_PARALLEL_FRAME_EVENT
					endelse
				endelse
			endelse
		endif

		if self.param_pos eq 0 then begin
			etalon = self.console -> get_etalon_info()
			self.leg1 = etalon.leg1_voltage
			self.leg2 = etalon.leg2_voltage
			self.leg3 = etalon.leg3_voltage
			if self.curr_leg eq 1 then self.nominal = self.leg1
			if self.curr_leg eq 2 then self.nominal = self.leg2
			if self.curr_leg eq 3 then self.nominal = self.leg3
		endif else begin
			;\\ Get parameter value from image
			hist = histogram(smooth(image, 100, /edge) - image)
			pfft = abs(fft(image))
			peak = where(hist eq max(hist))
			sharpness = hist(peak)
			self.param(self.param_pos-1) = pfft(0)
			print, peak

		endelse

		leg_val = self.nominal - self.step*(self.param_pos - 4)

		if self.curr_leg eq 1 then self.console -> update_legs, leg1=leg_val, /legs

		;\\ Update the leg and step values in display
		if self.curr_leg eq 1 then self.leg1 = leg_val
		if self.curr_leg eq 2 then self.leg2 = leg_val
		if self.curr_leg eq 3 then self.leg3 = leg_val

		leg1_id = widget_info(self.id, find_by_uname = 'AutoParallel_'+self.obj_num+'leg1')
		leg2_id = widget_info(self.id, find_by_uname = 'AutoParallel_'+self.obj_num+'leg2')
		leg3_id = widget_info(self.id, find_by_uname = 'AutoParallel_'+self.obj_num+'leg3')
		step_id = widget_info(self.id, find_by_uname = 'AutoParallel_'+self.obj_num+'step')

		widget_control, set_value = 'Leg1: ' + string(self.leg1,f='(i0)'), leg1_id
		widget_control, set_value = 'Leg2: ' + string(self.leg2,f='(i0)'), leg2_id
		widget_control, set_value = 'Leg3: ' + string(self.leg3,f='(i0)'), leg3_id
		widget_control, set_value = 'Step: ' + string(self.step,f='(i0)'), step_id

		self.param_pos = self.param_pos + 1

	endif

END_PARALLEL_FRAME_EVENT:
end


;\\ Retrieves the objects structure data for restoring, so only needs save info (required)

function SDIAutoParallel::get_settings

	struc = {id:self.id, wavelength:self.wavelength, geometry:self.geometry, need_timer:self.need_timer, $
			 need_frame:self.need_frame}

	return, struc

end


;\\ Cleanup routine

pro SDIAutoParallel::cleanup, log


end



pro SDIAutoParallel__define

	void = {SDIAutoParallel, id:0L, status:'', wavelength:0.0, start_time:0D, param:fltarr(9), $
							 step:0, nominal:0, leg1:0, leg2:0, leg3:0, curr_leg:0, param_pos:0, $
							 ref_image:ptr_new(/alloc), get_ref_flag:0, inherits XDIBase}

end