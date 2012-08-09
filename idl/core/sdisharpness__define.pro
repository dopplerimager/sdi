
function SDISharpness::init, restore_struc = restore_struc, data = data


	;\\ Generic Settings
		self.need_timer = 0
		self.need_frame = 1
		self.manager 	= data.manager
		self.console 	= data.console
		self.palette	= data.palette
		self.obj_num 	= string(data.count, format = '(i0)')

	;\\ Plugin Specific Settings
		self.xdim = data.xdim
		self.ydim = data.ydim

		if data.recover eq 1 then begin
			;\\ Saved settings
				xsize 			= 512
				ysize 			= 400
				xoffset 		= restore_struc.geometry.xoffset
				yoffset 		= restore_struc.geometry.yoffset
				self.best 		= restore_struc.best
				self.leg1_best 	= restore_struc.leg1_best
				self.leg2_best 	= restore_struc.leg2_best
				self.leg3_best 	= restore_struc.leg3_best
				self.xcen		= restore_struc.xcen
				self.ycen 		= restore_struc.ycen
		endif else begin
			;\\ Default settings
				xsize 	= 512
				ysize 	= 400
				xoffset = 100
				yoffset = 100
		endelse


	base = widget_base(group_leader = leader, xsize = xsize, ysize = ysize, xoff = xoffset, yoff = yoffset, title = 'Fringe Sharpness')

	plot_show = widget_draw(base, xsize = xsize, ysize = ysize-50, uname = 'Sharpness_'+self.obj_num+'_draw')

	center_button = widget_button(base, xoff=50, yoff=360, value = 'Find Center', font='Ariel*Bold*18', uval={tag:'get_center'})

	center_coords = widget_text(base, xoff=200, yoff=360, value = 'Current Center: ('+string(self.xcen,f='(i0)')+','+string(self.ycen,f='(i0)')+')', $
					font='Ariel*Bold*18', uname = 'Sharpness_'+self.obj_num+'coords', xsize=35)

	self.id = base

	widget_control, base, /realize

	return, 1

end


;\\ Finds the center of a fringe image

pro SDISharpness::get_center, event

	self.buffer -> get_buffer, image
	draw = 0

	find_center, image, self.xdim, self.ydim, draw=draw, tv_id=tv_id, fxcen, fycen
	self.xcen = fxcen
	self.ycen = fycen

	id = widget_info(self.id, find_by_uname='Sharpness_'+self.obj_num+'coords')
	widget_control, set_value = 'Current Center: ('+string(self.xcen,f='(i0)')+','+string(self.ycen,f='(i0)')+')', id

end


pro SDISharpness::frame_event, image, channel, scan

	view_id = widget_info(self.id, find_by_uname = 'Sharpness_'+self.obj_num+'_draw')
	widget_control, get_value = tv_id, view_id
	wset, tv_id

	image = image - min(smooth(image,5))
	;image = image/max(smooth(image,5))
	;xc = 1./(1.+total(image*shift(image, 0, 10)) + total(image*shift(image, 10, 0)))

	slice = image(*,255)
	corr = fltarr(19)
	arr = fltarr(19)

	for x = -9, 9 do begin
		corr(x+9) = (total(slice * shift(slice,x)))/100
		arr(x+9) = float(x)
	endfor

	corr = corr - min(corr)
	corr = corr / max(corr)
	fit = gaussfit(arr, corr)

	if self.bcount lt 9 then begin
		self.sbuffer(self.bcount) = fit(2)
		self.bcount = self.bcount + 1
	endif else begin

		if self.count lt 100 then begin
			self.history(self.count) = mean(self.sbuffer)
			self.count = self.count + 1
			if self.count eq 1 and self.best eq 0.0 then begin
				self.best = self.history(0)

			endif else begin
				if self.count gt 1 then begin
				if self.history(self.count-1) lt self.best then begin
					self.best = self.history(self.count-1)

				endif
				endif
			endelse
		endif else begin
			self.history = shift(self.history, -1)
			self.history(99) = mean(self.sbuffer)
			if self.history(99) lt self.best then begin
				self.best = self.history(99)

			endif
		endelse

		self.bcount = 0

	endelse

	!p.multi = 0
	!p.position = 0

	if self.count ge 1 then  begin
		plot, [0,100], [min(self.history), max(self.history)], /nodata, ytitle = 'Sharpness'
		oplot, self.history(0:self.count-1)
	endif

end


;\\ Retrieves the objects structure data for restoring, so only needs save info (required)

function SDISharpness::get_settings

	struc = {id:self.id, best:self.best, leg1_best:self.leg1_best, leg2_best:self.leg2_best, xcen:self.xcen, ycen:self.ycen, $
			 leg3_best:self.leg3_best, geometry:self.geometry, need_timer:self.need_timer, need_frame:self.need_frame}

	return, struc

end


;\\ Cleanup routine

pro SDISharpness::cleanup, log


end


pro SDISharpness__define

	void = {SDISharpness, id:0L, $
						  sbuffer:fltarr(10), $
						  history:fltarr(10000), $
						  count:0, $
						  bcount:0, $
						  best:0.0, $
						  leg1_best:0, $
						  leg2_best:0, $
						  leg3_best:0, $
						  xcen:0, $
						  ycen:0, $
						  xdim:0, $
						  ydim:0, $
						  inherits XDIBase}

end