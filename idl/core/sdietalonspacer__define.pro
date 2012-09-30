;\\ Code formatted by DocGen


;\D\<EtalonSpacer initialization.>
function SDIEtalonSpacer::init, data=data, $                     ;\A\<Misc data>
                                restore_struc=restore_struc      ;\A\<Restored settings>

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

	base = widget_base(group_leader = data.leader, xoff = xoff, yoff = yoff, $
						   title = 'SDI Etalon Spacer', col=1)

	lab1 = widget_label(base, value = 'Leg 1:', font=font)
	leg1 = widget_slider(base, xsize = 300, minim = 0, maxim = 4095, $
							 value = self.leg1, uvalue = {tag:'adjust_legs_event', leg:1}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg1')

	lab2 = widget_label(base, value = 'Leg 2:', font=font)
	leg2 = widget_slider(base, xsize = 300, minim = 0, maxim = 4095, $
							 value = self.leg2, uvalue = {tag:'adjust_legs_event', leg:2}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg2')

	lab3 = widget_label(base, value = 'Leg 3:', font=font)
	leg3 = widget_slider(base, xsize = 300, minim = 0, maxim = 4095, $
							 value = self.leg3, uvalue = {tag:'adjust_legs_event', leg:3}, $
							 uname = 'EtalonSpacer_'+self.obj_num+'leg3')

	axisbase = widget_base(base, col=4, /align_center)

	xplus  = widget_button(axisbase, value = 'X Axis +', font=font,  uval={tag:'tilt', dir:'x+'})
	xminus = widget_button(axisbase, value = 'X Axis -', font=font, uval={tag:'tilt', dir:'x-'})
	yplus  = widget_button(axisbase, value = 'Y Axis +', font=font,  uval={tag:'tilt', dir:'y+'})
	yminus = widget_button(axisbase, value = 'Y Axis -', font=font, uval={tag:'tilt', dir:'y-'})

	step_lab = widget_label(base, value = 'Step:', font=font)
	step = widget_text(base, /editable, font = font, value = string(self.step,f='(i0)'), /all, $
					   uval={tag:'step_change'}, uname='EtalonSpacer_'+self.obj_num+'step')

	tilt_label = widget_label(base, value = 'X Tilt: 0, Y Tilt: 0 ', font = font, $
								uname='EtalonSpacer_'+self.obj_num+'tilts', xsize = 400, /align_center)

	widget_control, base, /realize

	self.id = base
	tilts = self->get_tilts()


	return, 1

end


;\D\<Calcujlate X and Y tilts>
function SDIEtalonSpacer::get_tilts

	etalon = self.console -> get_etalon_info()
	leg1 = etalon.leg1_voltage
	leg2 = etalon.leg2_voltage
	leg3 = etalon.leg3_voltage

	widget_control, set_value = 'X Tilt: ' + string(leg1-leg2, f='(i0)') + $
								' Y Tilt: ' + string(leg2-leg3, f='(i0)'), $
					widget_info(self.id, find='EtalonSpacer_'+self.obj_num+'tilts')

	return, {x:leg1-leg2, y:leg2-leg3}

end

;\D\<Change the size of the tilt adjustment.>
pro SDIEtalonSpacer::step_change, event  ;\A\<Widget event>

	if event.type eq 0 or event.type eq 2 then begin

		step_id = widget_info(self.id, find='EtalonSpacer_'+self.obj_num+'step')
		widget_control, get_value = val, step_id
		self.step = fix(val(0))
		print, self.step

	endif

end

;\D\<A tilt event, for adjusting along the two orthogonal axes.>
pro SDIEtalonSpacer::tilt, event  ;\A\<Widget event>

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

	res = self->get_tilts()

end

;\D\<An event from the widget sloders representing leg voltages.>
pro SDIEtalonSpacer::adjust_legs_event, event  ;\A\<Widget event>

	widget_control, get_uval = uval, event.id

	if uval.leg eq 1 then self.leg1 = fix(event.value)
	if uval.leg eq 2 then self.leg2 = fix(event.value)
	if uval.leg eq 3 then self.leg3 = fix(event.value)

	self.console -> update_legs, leg1 = self.leg1, leg2 = self.leg2, leg3 = self.leg3, /legs
	res = self->get_tilts()

end

;\D\<Get settings for saving.>
function SDIEtalonSpacer::get_settings

	struc = {id:self.id, geometry:self.geometry, need_timer:self.need_timer, need_frame:self.need_frame}

	return, struc

end

;\D\<Cleanup - nothing to do>
pro SDIEtalonSpacer::cleanup, log  ;\A\<No Doc>

end

;\D\<The EtalonSpacer plugin allows you to adjust the etalon plate separation at each leg.>
;\D\<You can control each leg individually, or adjust paralellism along two orthogonal axes.>
pro SDIEtalonSpacer__define

	void = {SDIEtalonSpacer, id:0L, $
							 status:'', $
							 step:0, $
							 leg1:0, $
							 leg2:0, $
							 leg3:0, $
							 inherits XDIBase}

end
