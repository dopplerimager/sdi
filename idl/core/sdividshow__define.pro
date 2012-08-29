;\\ Code formatted by DocGen


;\D\<Initialize the Vidshow plugin.>
function SDIVidshow::init, restore_struc=restore_struc, $   ;\A\<Restored settings>
                           data=data                        ;\A\<Misc data from the console>

	self.need_timer = 0
	self.need_frame = 1
	self.manager 	= data.manager
	self.console 	= data.console
	self.palette	= data.palette
	self.obj_num 	= string(data.count, format = '(i0)')
	self.xdim		= data.xdim
	self.ydim		= data.ydim

	if data.recover eq 1 then begin
	print, 'Recovering'
		;\\ Saved settings
			xsize 	= data.xdim
			ysize 	= data.ydim
			xoffset	= restore_struc.geometry.xoffset
			yoffset	= restore_struc.geometry.yoffset
			self.scale = restore_struc.scale
			self.scale_fac = restore_struc.scale_fac
			self.grid = restore_struc.grid
			self.crosshairs = restore_struc.crosshairs
			self.crosshairs_point = restore_struc.crosshairs_point
	endif else begin
		;\\ Default settings
			xsize = data.xdim
			ysize = data.ydim
			xoffset = 100
			yoffset = 100
			self.scale_fac = 0.005
	endelse


	base = widget_base(xsize = xsize, ysize = ysize, xoffset = xoffset, yoffset = yoffset, mbar = menu, $
					   title = 'Vidshow', group_leader = leader)

	file_menu = widget_button(menu, value = 'File')

	vid_show = widget_draw(base, xsize = xsize, ysize = ysize, uname = 'Vidshow_' + self.obj_num + '_Vidarea')

	file_menu2 = widget_button(file_menu, value = 'Capture Image (.PNG)', uval = {tag:'image_capture', id:[vid_show], name:['Vidshow'], type:'png'})
	file_menu3 = widget_button(file_menu, value = 'Capture Image (.JPG)', uval = {tag:'image_capture', id:[vid_show], name:['Vidshow'], type:'jpg'}, $
								uname = 'Vidshow_'+self.obj_num+'_jpg')
	file_menu4 = widget_button(file_menu, value = 'Fit Window to Image',  uval = {tag:'fit_window'})

	if self.scale eq 1 then str = 'Turn Auto Scaling OFF' else str = 'Turn Auto Scaling ON'
	file_menu5 = widget_button(file_menu, value = str,  uval = {tag:'scaling'}, uname = 'Vidshow_' + self.obj_num + '_Scaler')
	file_menu6 = widget_button(file_menu, value = 'Set Manual Scale Factor',  uval = {tag:'set_scale'})

	if self.crosshairs eq 1 then str = 'Turn Crosshairs OFF' else str = 'Turn Crosshairs ON'
	if self.grid eq 1 then gstr = 'Turn Grid OFF' else gstr = 'Turn Grid ON'

	file_menu7 = widget_button(file_menu, value = gstr,  uval = {tag:'set_grid'}, uname = 'Vidshow_' + self.obj_num + '_grid')
	file_menu8 = widget_button(file_menu, value = str,  uval = {tag:'set_crosshairs'}, uname = 'Vidshow_' + self.obj_num + '_crosshairs')
	file_menu9 = widget_button(file_menu, value = 'Set Crosshair Intersect',  uval = {tag:'set_crosshairs_point'})

	file_menu10 = widget_button(file_menu, value = 'Set Color Table',  uval = {tag:'set_color_table'})
	file_menu11 = widget_button(file_menu, value = 'Turn Quadrant Masking ON',  uval = {tag:'mask_quadrants'}, $
						uname = 'Vidshow_' + self.obj_num + '_masker')

	self.id = base

	widget_control, base, /realize

	return, 1

end

;\D\<Toggle between using the manual scale factor and auto scaling, called from the menu.>
pro SDIVidshow::scaling, event  ;\A\<Widget event>

	if self.scale eq 1 then self.scale = 0 else self.scale = 1
	btn_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_Scaler')
	if self.scale eq 1 then str = 'Turn Auto Scaling OFF' else str = 'Turn Auto Scaling ON'
	widget_control, set_value = str, btn_id

end

;\D\<Mask out most of the four quadrants of the image, leaving only a small `cross' of the>
;\D\<image left to display, helps for slow connections, called from the menu.>
pro SDIVidshow::mask_quadrants, event  ;\A\<Widget event>

	if self.mask_quadrants eq 1 then self.mask_quadrants = 0 else self.mask_quadrants = 1
	btn_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_masker')
	if self.mask_quadrants eq 1 then str = 'Turn Quadrant Masking OFF' else str = 'Turn Quadrant Masking ON'
	widget_control, set_value = str, btn_id

end

;\D\<Set a manual scale value applied to image prior to display, called from the menu.>
pro SDIVidshow::set_scale, event  ;\A\<Widget event>

	s = self.scale_fac
	xvaredit, s, name = 'Set Image Gain Factor', group = self.id
	self.scale_fac = s

end

;\D\<Toggle on/off displaying a grid overlay, called from the menu.>
pro SDIVidshow::set_grid, event  ;\A\<Widget event>

	if self.grid eq 1 then self.grid = 0 else self.grid = 1
	btn_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_grid')
	if self.grid eq 1 then str = 'Turn Grid OFF' else str = 'Turn Grid ON'
	widget_control, set_value = str, btn_id

end

;\D\<Toggle on/off diaplying the crosshairs, called from the menu.>
pro SDIVidshow::set_crosshairs, event  ;\A\<Widget event>

	if self.crosshairs eq 1 then self.crosshairs = 0 else self.crosshairs = 1
	btn_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_crosshairs')
	if self.crosshairs eq 1 then str = 'Turn Crosshairs OFF' else str = 'Turn Crosshairs ON'
	widget_control, set_value = str, btn_id

end

;\D\<Set where the crosshairs intersect (x, y), called from the menu.>
pro SDIVidshow::set_crosshairs_point, event  ;\A\<Widget event>

	pnt = self.crosshairs_point
	xvaredit, pnt, name = 'Set Crosshair X and Y Intersect', group = self.id
	self.crosshairs_point = pnt

end

;\D\<Receive a new camera frame, scale it and display.>
pro SDIVidshow::frame_event, image, $     ;\A\<Latest camera image>
                             channel      ;\A\<Current scan channel>

	vid_image = image - min(image)

	if self.mask_quadrants eq 1 then begin
		wid = 20
		vid_image[0:self.xdim/2 - wid, 0:self.ydim/2 - wid] = 0
		vid_image[self.xdim/2 + wid:self.xdim-1, 0:self.ydim/2 - wid] = 0
		vid_image[self.xdim/2 + wid:self.xdim-1, self.ydim/2 + wid:self.ydim-1] = 0
		vid_image[0:self.xdim/2 - wid, self.ydim/2 + wid:self.ydim-1] = 0

		;slice_img = vid_image*0.
		;slice_img[256-wid:256+wid, *] = vid_image[256-wid:256+wid, *]
		;slice_img[*, 256-wid:256+wid] = vid_image[*, 256-wid:256+wid]
		;vid_image = slice_img
	endif

	view_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_Vidarea')
	widget_control, get_value = tv_id, view_id

	geom = widget_info(self.id, /geom)
	widget_control, xsize = geom.xsize, ysize = geom.ysize, view_id


	if geom.xsize ne self.xdim or geom.ysize ne self.ydim then vid_image = congrid(image, geom.xsize, geom.ysize)


	loadct, self.color_table, /silent
	wset, tv_id
	scl = self.scale_fac
	if self.scale_fac eq 0 then scl = max(vid_image)
	if self.scale eq 1 then tv, bytscl(vid_image) else tv, vid_image*scl
	load_pal, self.palette

	if self.crosshairs eq 1 then begin
		plots, self.crosshairs_point(0), 0, /device, color=self.palette.ash
    	plots, self.crosshairs_point(0), geom.ysize, /device, color=self.palette.ash, /continue

		plots, 0, self.crosshairs_point(1), /device, color=self.palette.ash
    	plots, geom.xsize, self.crosshairs_point(1), /device, color=self.palette.ash, /continue
    endif

	if self.grid eq 1 then begin
		xs = geom.xsize
		ys = geom.ysize
		for x = 0, xs, 10 do plots, [x,x], [0,ys], color=self.palette.ash, /device
		for y = 0, ys, 10 do plots, [0,xs], [y,y], color=self.palette.ash, /device
    endif

	self.framecount = self.framecount + 1
	xyouts, /normal, 0.5, 0.05, string(1./(systime(1, /sec) - self.tstrt), format = '(f4.1)') + ' Hz', align=0.5
	self.tstrt = systime(1, /sec)

end

;\D\<Resize the window to fit the native resolution of the camera image, called from the menu.>
pro SDIVidshow::fit_window, event  ;\A\<Widget event>

	view_id = widget_info(self.id, find_by_uname = 'Vidshow_' + self.obj_num + '_Vidarea')
	widget_control, xsize = self.xdim, ysize = self.ydim, view_id
	widget_control, xsize = self.xdim, ysize = self.ydim, self.id

end

;\D\<Set the color table, called when user selects this option from the menu.>
pro SDIVidshow::set_color_table, event  ;\A\<Widget event>

	c = self.color_table
	xvaredit, c, name = 'Set Color Table Index:', group = self.id
	self.color_table = c

end

;\D\<Get settings to save.>
function SDIVidshow::get_settings

	struc = {id:self.id, $
			 need_timer:self.need_timer, $
			 need_frame:self.need_frame, $
			 scale:self.scale, $
			 scale_fac:self.scale_fac, $
			 geometry:self.geometry, $
			 exp_time:self.exp_time, $
			 crosshairs:self.crosshairs, $
			 crosshairs_point:self.crosshairs_point, $
			 grid:self.grid}

	return, struc

end

;\D\<Cleanup - nothing to do.>
pro SDIVidshow::cleanup, log  ;\A\<No Doc>


end

;\D\<The Vidshow plugin displays the latest camera images as they are recorded.>
pro SDIVidshow__define

	void = {SDIVidshow, id: 0L, inst:0, exp_time: 0.03, xdim:0, ydim:0, scale:0, scale_fac:0.005, $
			crosshairs:0, crosshairs_point:intarr(2), grid:0, color_table:0, framecount: 0L, tstrt: systime(1, /sec), $
			mask_quadrants:0, inherits XDIBase}

end
