
function SDIEtalonSpacer::init, data=data, restore_struc = restore_struc

	self.palette = data.palette
	self.need_timer = 0
	self.need_frame = 0
	self.obj_num = string(data.count, format = '(i0)')
	self.manager = data.manager
	self.console = data.console


	if data.recover eq 1 then begin

		;\\ Saved settings

		xsize 			= 470	;restore_struc.geometry.xsize
		ysize 			= 300	;restore_struc.geometry.ysize
		xoffset 		= restore_struc.geometry.xoffset
		yoffset 		= restore_struc.geometry.yoffset

	endif else begin

		;\\ Default settings

		xsize 	= 470
		ysize 	= 300
		xoffset = 100
		yoffset = 100

	endelse

	font = 'Ariel*Bold*20'

	etalon = self.console -> get_etalon_info()
	self.leg1 = etalon.leg1_voltage
	self.leg2 = etalon.leg2_voltage
	self.leg3 = etalon.leg3_voltage

	font = 'Ariel*15*Bold'

	base = widget_base(group_leader = data.leader, xsize = xsize, ysize = ysize, xoff = xoff, yoff = yoff, $
						   title = 'SDI Etalon Spacer')

	lab1 = widget_label(base, value = 'Leg 1:', yoffset = 35, xoffset = 10, font=font)
	lab2 = widget_label(base, value = 'Leg 2:', yoffset = 85, xoffset = 10, font=font)
	lab3 = widget_label(base, value = 'Leg 3:', yoffset = 135, xoffset = 10, font=font)

	leg1 = widget_slider(base, xsize = 300, xoffset = 50, yoffset = 20, minim = 0, maxim = 4095, $
							 value = self.leg1, uvalue = {tag:'adjust_legs_event', leg:1}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg1')
	leg2 = widget_slider(base, xsize = 300, xoffset = 50, yoffset = 70, minim = 0, maxim = 4095, $
							 value = self.leg2, uvalue = {tag:'adjust_legs_event', leg:2}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg2')
	leg3 = widget_slider(base, xsize = 300, xoffset = 50, yoffset = 120, minim = 0, maxim = 4095, $
							 value = self.leg3, uvalue = {tag:'adjust_legs_event', leg:3}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg3')

	step_lab = widget_label(base, xo = 10, yo = 180, value = 'Step:', font=font)
	step = widget_text(base, /editable, xo = 40, yo = 180, font = font, value = string(self.step,f='(i0)'), /all, $
					   uval={tag:'step_change'}, uname='EtalonSpacer_'+self.obj_num+'step')

	xplus  = widget_button(base, xo = 10, yo = 220, value = 'X Axis +', font=font,  uval={tag:'tilt', dir:'x+'})
	xminus = widget_button(base, xo = 100, yo = 220, value = 'X Axis -', font=font, uval={tag:'tilt', dir:'x-'})
	yplus  = widget_button(base, xo = 10, yo = 260, value = 'Y Axis +', font=font,  uval={tag:'tilt', dir:'y+'})
	yminus = widget_button(base, xo = 100, yo = 260, value = 'Y Axis -', font=font, uval={tag:'tilt', dir:'y-'})

	widget_control, base, /realize

	self.id = base

	return, 1

end


pro SDIEtalonSpacer::step_change, event

	if event.type eq 0 or event.type eq 2 then begin

		step_id = widget_info(self.id, find='EtalonSpacer_'+self.obj_num+'step')
		widget_control, get_value = val, step_id
		self.step = fix(val(0))
		print, self.step

	endif

end


pro SDIEtalonSpacer::tilt, event

	widget_control, get_uval = uval, event.id

	case uval.dir of

		'x+':begin
				new_leg1 = self.leg1 + self.step
				new_leg2 = self.leg2 - self.step
				new_leg3 = self.leg3 - self.step
			end

		'x-':begin
				new_leg1 = self.leg1 - self.step
				new_leg2 = self.leg2 + self.step
				new_leg3 = self.leg3 + self.step
			end

		'y+':begin
				new_leg1 = self.leg1
				new_leg2 = self.leg2 + self.step
				new_leg3 = self.leg3 - self.step
			end

		'y-':begin
				new_leg1 = self.leg1
				new_leg2 = self.leg2 - self.step
				new_leg3 = self.leg3 + self.step
			end

	endcase

	if new_leg1 le 4095 and new_leg2 le 4095 and new_leg3 le 4095 then begin
		if new_leg1 ge 0 and new_leg2 ge 0 and new_leg3 ge 0 then begin
			self.leg1 = new_leg1
			self.leg2 = new_leg2
			self.leg3 = new_leg3
			self.console -> update_legs, leg1 = self.leg1, leg2 = self.leg2, leg3 = self.leg3, /legs
		endif
	endif

	leg1_id = widget_info(self.id, find_by_uname = 'EtalonSpacer_'+self.obj_num+'leg1')
	leg2_id = widget_info(self.id, find_by_uname = 'EtalonSpacer_'+self.obj_num+'leg2')
	leg3_id = widget_info(self.id, find_by_uname = 'EtalonSpacer_'+self.obj_num+'leg3')

	widget_control, leg1_id, set_val = self.leg1
	widget_control, leg2_id, set_val = self.leg2
	widget_control, leg3_id, set_val = self.leg3

end

pro SDIEtalonSpacer::adjust_legs_event, event

	widget_control, get_uval = uval, event.id

	if uval.leg eq 1 then self.leg1 = fix(event.value)
	if uval.leg eq 2 then self.leg2 = fix(event.value)
	if uval.leg eq 3 then self.leg3 = fix(event.value)

	self.console -> update_legs, leg1 = self.leg1, leg2 = self.leg2, leg3 = self.leg3, /legs

end


function SDIEtalonSpacer::get_settings

	struc = {id:self.id, geometry:self.geometry, need_timer:self.need_timer, need_frame:self.need_frame}

	return, struc

end


;\\ Cleanup routine

pro SDIEtalonSpacer::cleanup, log


end


pro SDIEtalonSpacer__define

	void = {SDIEtalonSpacer, id:0L, $
							 status:'', $
							 step:0, $
							 leg1:0, $
							 leg2:0, $
							 leg3:0, $
							 inherits XDIBase}

end








