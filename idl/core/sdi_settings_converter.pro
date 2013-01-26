
pro converter_write_settings, self, $
							  filename, $
							  pfilename

	outname = filename
	proname = (strsplit(file_basename(filename), '.', /extract))[0]

	tab = string(9B)
	newline = string([13B,10B])

	openw, hnd, outname, /get
	printf, hnd, 'pro ' + proname + ', data'
	printf, hnd, newline + tab + ';\\ ETALON'
	printf, hnd, converter_write_settings_struc('etalon', self.etalon, tab)
	printf, hnd, newline + tab + ';\\ CAMERA'
	printf, hnd, converter_write_settings_struc('camera', self.camera, tab)
	printf, hnd, newline + tab + ';\\ HEADER'
	printf, hnd, converter_write_settings_struc('header', self.header, tab)
	printf, hnd, newline + tab + ';\\ LOGGING'
	printf, hnd, converter_write_settings_struc('logging', self.logging, tab)
	printf, hnd, newline + tab + ';\\ MISC'
	printf, hnd, converter_write_settings_struc('misc', self.misc, tab)
	printf, hnd, 'end'
	close, hnd
	free_lun, hnd

	outname = pfilename

	persistent =  {$

				   etalon:{phasemap_base:*self.etalon.phasemap_base, $
				   		   phasemap_grad:*self.etalon.phasemap_grad, $
				   		   phasemap_time:self.etalon.phasemap_time, $
				   		   nm_per_step_time:self.etalon.nm_per_step_time, $
				   		   phasemap_lambda:self.etalon.phasemap_lambda, $
				   		   leg1_voltage:self.etalon.leg1_voltage, $
				   		   leg2_voltage:self.etalon.leg2_voltage, $
				   		   leg3_voltage:self.etalon.leg3_voltage }, $

				   misc:{motor_cur_pos:self.misc.motor_cur_pos, $
				   		 current_filter:self.misc.current_filter, $
				   		 current_source:self.misc.current_source} $

				   }

	save, filename = outname, persistent

end

;\D\<Return a string version of a struc for the settings file.>
function converter_write_settings_struc, name, struc, indent
	str = ''
	names = tag_names(struc)
	edits = where(names eq 'EDITABLE', edits_yn)

	for i = 0, n_tags(struc) - 1 do begin

		if strupcase(name) eq 'MISC' and $
		   (names[i] eq 'PORT_MAP' or names[i] eq 'SOURCE_MAP') then begin
			can_edit = 1
		endif else begin
			if edits_yn eq 1 then match = where(struc.editable eq i, can_edit) $
				else can_edit = 1
		endelse

		if can_edit eq 1 then str += converter_write_settings_field(name + '.' + names[i], $
																struc.(i), indent) + string([13B,10B])
	endfor
	return, str
end

;\D\<Return a string version of a field for the settings file.>
function converter_write_settings_field, name, field, indent
	if size(field, /type) eq 8 then begin
		return, converter_write_settings_struc(name, field, indent)
	endif else begin
		is_string = 0
		case size(field, /type) of
			1: fmt = '(i0)'
			2: fmt = '(i0)'
			3: fmt = '(i0)'
			4: fmt = '(f0)'
			7: is_string = 1
		endcase
		if is_string eq 0 then return, indent + 'data.' + name + ' = ' + string(field, f=fmt) $
			else return, indent + 'data.' + name + " = '" + field + "'"
	endelse
end

pro sdi_settings_converter, infile

	restore, infile

	self = {etalon:etalon, $
			camera:camera, $
			header:header, $
			logging:logging, $
			misc:misc}

	proname = (strsplit(file_basename(infile), '.', /extract))[0]
	outpath = file_dirname(infile) + '\'
	fname = outpath + proname + '.pro'
	pfname = outpath + proname + '_persistent.idlsave'

	converter_write_settings, self, $
							  fname, $
							  pfname

end
