
;\\ Event handler

pro Tree_Event, event

	COMMON one, var_holder, base, leader_id, namesave, miscData

	widget_control, get_uvalue = uval, event.id

	if size(uval, /type) eq 7 then begin
		if uval eq 'save' then edit_save_settings
		if uval eq 'load' then edit_load_settings
		if uval eq 'ports' then edit_port_settings
		if uval eq 'save_and_apply' then begin
			edit_save_settings, filename = miscData.filename, /nosplash
			miscData.console -> load_settings, 0, filename = miscData.filename
		endif
	endif else begin
		if size(uval, /type) eq 8 then begin
		if event.type eq 0 and uval.type eq 'leaf' then begin
			if event.clicks eq 2 then begin
				var_names = tag_names(var_holder.(uval.root))
				this_name = var_names(uval.leaf)
				var = var_holder.(uval.root).(uval.leaf)
				xvaredit, var, group = uval.base, name = this_name
				var_holder.(uval.root).(uval.leaf) = var
				case size(var_holder.(uval.root).(uval.leaf), /type) of
					1: fmt = '(i0)'
					2: fmt = '(i0)'
					3: fmt = '(i0)'
					4: fmt = '(f0)'
					7: fmt = ''
				endcase
				widget_control, set_value = this_name+': '+string(var_holder.(uval.root).(uval.leaf), format=fmt), event.id
			endif
		endif
		endif
	endelse

end


;\\ Tree cleanup

pro Tree_Cleanup, id

	COMMON one, var_holder, base, leader_id, namesave, miscData

	if leader_id ne 0L then widget_control, send_event = {id:0L, top:0L, handler:0L, tag:'editor_closed'}, leader_id

end


;\\ Save the settings

pro edit_save_settings, filename = filename, nosplash=nosplash

	COMMON one, var_holder, base, leader_id, namesave, miscData

	if not keyword_set(filename) then begin
		fname = dialog_pickfile(/write, file=namesave)
	endif else begin
		fname = miscData.filename
	endelse

	save_names = tag_names(var_holder)

	str = ''
	for n = 0, n_elements(save_names) - 1 do begin
		res = execute(save_names(n) + ' = ' + 'var_holder.(n)')
		str = str + save_names(n)
		if n ne n_elements(save_names) - 1 then str = str + ', '
	endfor
		print, str
	res = execute('save, filename = fname, save_names, ' + str)

	if not keyword_set(nosplash) then res = dialog_message('File Saved', /info)

end

;\\ Load settings

pro edit_load_settings, filename = filename

	COMMON one, var_holder, base, leader_id, namesave, miscData

	if not keyword_set(filename) then begin
		filename = dialog_pickfile()
	endif

	miscData.filename = filename

	restore, filename, /relaxed

	var_names = tag_names(var_holder)

	if n_elements(var_names) ne n_elements(save_names) then begin
		mess = ['NOT COMPATIBLE WITH CURRENT SETTINGS INFORMATION, CANNOT LOAD.', $
				'ERROR - WRONG NUMBER OF SETTINGS CATEGORIES:', $
				'LOAD FILE HAS ' + string(n_elements(save_names), f='(i0)')+', EXPECTING ' + string(n_elements(var_names),f='(i0)')]
		res = dialog_message(mess)
		goto, END_LOAD
	endif

	for n = 0, n_elements(save_names) - 1 do begin

		match = where(save_names(n) eq var_names, matchyn)
		if matchyn eq 0 then begin
			mess = ['NOT COMPATIBLE WITH CURRENT SETTINGS INFORMATION, CANNOT LOAD.', $
			  		'ERROR - NO MATCHING CATEGORY FOR SAVE FILE VARIABLE ' + save_names(n)]
			res = dialog_message(mess)
			goto, END_LOAD
		endif

		tag = match(0)

		res = execute('new_tags = n_tags(' + save_names(n) + ')')

		if new_tags ne n_tags(var_holder.(tag)) then begin
			mess = ['NOT COMPATIBLE WITH CURRENT SETTINGS INFORMATION, CANNOT LOAD.', $
			  		'ERROR - TAGS IN CATEGORY: ' + save_names(n) + ' DONT MATCH THOSE EXPECTED']
			res = dialog_message(mess)
			goto, END_LOAD
		endif else begin
			res = execute('tags_to_load = ' + save_names(n) + '.editable')
			for t = 0, n_elements(tags_to_load) - 1 do begin
				res = execute('var_holder.(tag).(tags_to_load(t)) = ' + save_names(n) + '.(tags_to_load(t))')
			endfor

		endelse

	endfor


	;\\ Initialize the image and phasemap arrays
		xpix = var_holder.camera.xpix > 1
		ypix = var_holder.camera.ypix > 1
		x_dimension = ceil(xpix/float(var_holder.camera.xbin))
		y_dimension = ceil(ypix/float(var_holder.camera.ybin))

		var_holder.etalon.phasemap_base = ptr_new(/alloc)
		*var_holder.etalon.phasemap_base = intarr(x_dimension, y_dimension)
		var_holder.etalon.phasemap_grad = ptr_new(/alloc)
		*var_holder.etalon.phasemap_grad = intarr(x_dimension, y_dimension)
		var_holder.etalon.phasemap_lambda = etalon.phasemap_lambda

		if size(*etalon.phasemap_base, /type) ne 0 then begin
			phase_tmp = *etalon.phasemap_base
			if n_elements(phase_tmp(*,0)) eq x_dimension and n_elements(phase_tmp(0,*)) eq y_dimension then begin
				*var_holder.etalon.phasemap_base = phase_tmp
			endif
			phase_tmp = *etalon.phasemap_grad
			if n_elements(phase_tmp(*,0)) eq x_dimension and n_elements(phase_tmp(0,*)) eq y_dimension then begin
				*var_holder.etalon.phasemap_grad = phase_tmp
			endif
		endif

	;\\ Add in the phasemap and nm/step times
		var_holder.etalon.phasemap_time = etalon.phasemap_time
		var_holder.etalon.nm_per_step_time = etalon.nm_per_step_time

	;\\ Add in the saved port mappings, current filter, mirror pos
		var_holder.misc.port_map = misc.port_map
		var_holder.misc.current_filter = misc.current_filter
		var_holder.misc.motor_cur_pos = misc.motor_cur_pos
		var_holder.misc.source_map = misc.source_map
		var_holder.misc.current_source = misc.current_source

	REFRESH_VIEW:

	for n = 0, n_elements(var_names) - 1 do begin
		leaf_names = tag_names(var_holder.(n))
		for l = 0, n_elements(leaf_names) - 1 do begin
			match = where(l eq var_holder.(n).(n_tags(var_holder.(n)) - 1), edityn)
			if edityn eq 1 then begin
				idname = var_names(n) + '_' + leaf_names(l)
				id = widget_info(base, find_by_uname = idname)
				case size(var_holder.(n).(l), /type) of
					1: fmt = '(i0)'
					2: fmt = '(i0)'
					3: fmt = '(i0)'
					4: fmt = '(f0)'
					7: fmt = ''
				endcase
				widget_control, set_value = leaf_names(l) + ': ' + string(var_holder.(n).(l), format=fmt), id
			endif
		endfor
	endfor



END_LOAD:
end


pro edit_port_settings

	COMMON one, var_holder, base, leader_id, namesave, miscData

	struc = var_holder.misc.port_map
	xvaredit, struc, name = 'Port Mappings', group=base
	var_holder.misc.port_map = struc
	help, var_holder.misc.port_map, /struc

end

;\\ Set up the structures

pro define_variables, var_holder

;\\ Load a palette prototype
	load_pal, culz, idl=[3,1]

;\\ Count the plugins
	paths = Get_Paths()
	path_list = file_search(paths, 'SDI*__define.pro', count = nmods)

;\\ Console settings
etalon = {eta,	  number_of_channels:0, $
						 current_channel:0, $
							 leg1_offset:0.0, $
					         leg2_offset:0.0, $
					         leg3_offset:0.0, $
							leg1_voltage:0, $
						    leg2_voltage:0, $
					        leg3_voltage:0, $
					   leg1_base_voltage:0, $
					   leg2_base_voltage:0, $
					   leg3_base_voltage:0, $
					         nm_per_step:0.0, $
					    nm_per_step_time:0D, $
			   nm_per_step_refresh_hours:0.0, $
					gap_refractive_index:0.0, $
								scanning:0, $		;\\ 2 = scan paused
					   start_volt_offset:0, $
						stop_volt_offset:0, $
					      volt_step_size:0.0, $
					       phasemap_base:ptr_new(/alloc), $
					       phasemap_grad:ptr_new(/alloc), $
					     phasemap_lambda:0.0, $
					       phasemap_time:0D, $
				  phasemap_refresh_hours:0.0, $
				  					 gap:0.0, $
				  		     max_voltage: 4095, $
				    		    editable:[0,2,3,4,8,9,10,11,13,14,23,24,25]}

camera = {cam, 	 exposure_time:0.0, $
					       read_mode:0, $
					acquisition_mode:0, $
					    trigger_mode:0, $
					    shutter_mode:0, $
				shutter_closing_time:0, $
				shutter_opening_time:0, $
				    vert_shift_speed:0, $
				    	   cooler_on:0, $
				    	 cooler_temp:0, $
				    	    fan_mode:0, $
				    	    cam_temp:0.0, $
				    	  temp_state:'', $
				    	        xbin:0, $
				    	        ybin:0, $
				   wait_for_min_temp:0, $
				   wait_for_shutdown:0, $
				        cam_min_temp:0.0, $
				        cam_max_temp:0.0, $
				       cam_safe_temp:0.0, $
				       			gain:0, $
				       			xcen:0, $
				       			ycen:0, $
	 	       			 preamp_gain:0, $
	 	       		  baseline_clamp:0, $
	 	       		    em_gain_mode:0, $
	 	       		    vs_amplitude:0, $
	 	       		      ad_channel:0, $
	 	       		output_amplifier:0, $
	 	       				hs_speed:0, $
	 	       					xpix:0, $
	 	       					ypix:0, $
			 			    editable:[0,1,2,3,4,5,6,7,8,9,10,11,13,14,20,21,22,23,24,25,26,27,28,29,30,31]}


	header = {hea,        records:0, $
				   file_specifier:'', $
				             site:'', $
				        site_code:'', $
				  instrument_name:'', $
				        longitude:0.0, $
				         latitude:0.0, $
				             year:'', $
				              doy:'', $
				         operator:'', $
				          comment:'', $
				         software:'', $
				            notes:replicate(string(' ', format = '(a80)'), 32), $
				   	     editable:[2,3,4,5,6,7,8,9,10,11]}

   	logging = {log,    log_directory:'', $
				    time_name_format:'', $
				      enable_logging:0, $
				       log_overwrite:0, $
				          log_append:0, $
				        ftp_snapshot:'', $
				        		 log:strarr(100), $
				         log_entries:0, $
				    	    editable:[0,1,2,3,4,5]}

;	port_map_struc = {pms, mirror:0L, cal_source:0L, etalon:0L}
    interface_info = {ifs, number: 0L, type: 'unknown', settings: 'none'}
	port_map_struc = {pms, mirror: interface_info, cal_source: interface_info, etalon: interface_info, filter: interface_info}
	source_map_struc = {sms, s0:0, s1:0, s2:0, s3:0}

	misc = {mis, default_settings_path:'', $
				   screen_capture_path:'', $
				        phase_map_path:'', $
				         zone_set_path:'', $
				          spectra_path:'', $
				              dll_name:'C:\Program Files\Microsoft Visual Studio\MyProjects\dlltest\debug\dlltest.dll', $
				   timer_tick_interval:0.0, $
				               palette:culz, $
				      shutdown_on_exit:0, $
				          object_count:0, $
				              timer_id:0L, $
				             timer2_id:0L, $
							console_id:0L, $
						 		log_id:0L, $
						 active_object:obj_new(), $
						 schedule_line:0L, $
						 motor_sky_pos:0L, $
						 motor_cal_pos:0L, $
						 motor_cur_pos:0L, $
						current_filter:0,  $
						current_source:0,  $
						 	  port_map:port_map_struc, $
						 	source_map:source_map_struc, $
						 snapshot_time:0D, $
				snapshot_refresh_hours:0.0, $
						      editable:[0,1,2,3,4,5,6,8,16,17,24]}



	var_holder = {etalon:etalon, camera:camera, header:header, logging:logging, misc:misc}

end


;\\ MAIN PROGRAM ##############################################################################

pro edit_console_settings, filename = filename, $
						   leader = leader, $
						   console = console

	COMMON one, var_holder, base, leader_id, namesave, miscData

	miscData = {filename:'', $
				console:obj_new()}

	if keyword_set(console) then begin
		if obj_valid(console) then begin
			miscData.console = console
		endif
	endif

	if keyword_set(leader) then begin
		leader_id = leader
	endif else begin
		leader_id = 0L
		leader = 0L
	endelse

	define_variables, var_holder

	nroots = n_tags(var_holder)
	root_names = tag_names(var_holder)

	base = widget_base(group_leader = leader, title = 'SETTINGS FILE EDITOR FOR SDI CONSOLE', mbar = menu, $
					   col = 1)

	file = widget_button(menu, value = 'File')
	fsave = widget_button(file, value = 'Save', uval = 'save')
	fload = widget_button(file, value = 'Load', uval = 'load')
	fports = widget_button(file, value = 'Ports', uval = 'ports')

	wtree = widget_tree(base, xsize = 500, ysize = 800)
	wroots = lonarr(nroots)

	max_leaves = 0

	for n = 0, nroots - 1 do begin
		wroots(n) = widget_tree(wtree, value = root_names(n), /folder, uval = {type:'root'})
		if n_tags(var_holder.(n)) gt max_leaves then max_leaves = n_tags(var_holder.(n))
	endfor

	wleaves = lonarr(nroots, max_leaves-1)
	leaf_count = intarr(nroots)

	for n = 0, nroots - 1 do begin
		sub_names = tag_names(var_holder.(n))
		for l = 0, n_tags(var_holder.(n)) - 1 do begin
			match = where(l eq var_holder.(n).(n_tags(var_holder.(n)) - 1), edityn)
			if edityn eq 1 then begin
				case size(var_holder.(n).(l), /type) of
					1: fmt = '(i0)'
					2: fmt = '(i0)'
					3: fmt = '(i0)'
					4: fmt = '(f0)'
					7: fmt = ''
				endcase
				wleaves(n,leaf_count(n)) = widget_tree(wroots(n), value = sub_names(l)+': '+string(var_holder.(n).(l), format=fmt), $
						uvalue = {type:'leaf', root:n, leaf:l, base:base}, uname = root_names(n) + '_' + sub_names(l))
				leaf_count(n) = leaf_count(n) + 1
			endif
		endfor
	endfor

	if obj_valid(miscData.console) then begin
		save_and_apply = widget_button(base, value = 'Save and Apply', uval='save_and_apply')
	endif

	widget_control, /realize, base

	if keyword_set(filename) then begin
		edit_load_settings, filename = filename
		namesave = filename
	endif else namesave = ''


	xmanager, 'edit_console_settings', base, event_handler = 'Tree_Event', cleanup = 'Tree_Cleanup'

end
