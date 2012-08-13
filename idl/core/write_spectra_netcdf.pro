;\\ Code formatted by DocGen


;\D\<No Doc>
pro Write_Spectra_NetCDF, ncdid, $                 ;\A\<No Doc>
                          spectra, $               ;\A\<No Doc>
                          start_time, $            ;\A\<No Doc>
                          end_time, $              ;\A\<No Doc>
                          nscans, $                ;\A\<No Doc>
                          acc_im, $                ;\A\<No Doc>
                          create=create, $         ;\A\<No Doc>
                          fname=fname, $           ;\A\<No Doc>
                          return_id=return_id, $   ;\A\<No Doc>
                          header=header, $         ;\A\<No Doc>
                          data=data, $             ;\A\<No Doc>
                          reopen=reopen, $         ;\A\<No Doc>
                          update=update            ;\A\<No Doc>

	;\\ Find dimensions
		nchannels = n_elements(spectra(0,*))
		nzones = n_elements(spectra(*,0))

	;\\
		if keyword_set(reopen) then begin
			if keyword_set(fname) then ncdid = ncdf_open(fname, /write)
			return_id = ncdid
			goto, END_WRITE_SPECTRA_NETCDF
		endif

		if keyword_set(update) then begin
			if keyword_set(fname) then ncdid = ncdf_open(fname, /write)
			return_id = ncdid
		endif

		if not keyword_set(create) then begin

			;\\ File exists, and is open, append the spectra data

				spex_id = ncdf_varid(ncdid, 'Spectra')
				time_id = ncdf_dimid(ncdid, 'Time')
				zone_id = ncdf_dimid(ncdid, 'Zone')
				chan_id = ncdf_dimid(ncdid, 'Channel')


				ncdf_diminq, ncdid, time_id, dummy, time_index

				ncdf_control, ncdid, /sync

				print, time_index


			;\\ Write the variables
				ncdf_varput, ncdid, ncdf_varid(ncdid, 'Start_Time'),            start_time, 			offset = [time_index]
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'End_Time'),              end_time,   			offset = [time_index]
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),          nscans,     			offset = [time_index]
				ncdf_varput, ncdid, ncdf_varid(ncdid, 'X_Center'),              data.x_center, 			offset = [time_index]
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Y_Center'),              data.y_center, 			offset = [time_index]
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Nm_Per_Step'),           data.nm_per_step, 		offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg1_Start_Volt'),  	    data.leg1_start_volt, 	offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg2_Start_Volt'),  	    data.leg2_start_volt, 	offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg3_Start_Volt'),  	    data.leg3_start_volt, 	offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),  	    	data.cam_temp, 			offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),  		    data.cam_gain, 			offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'), 	 	    data.cam_exptime, 		offset = [time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Spectra'), 				spectra, 				offset = [0,0,time_index]
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'), 	acc_im, 				offset = [0,0,time_index]

			;\\ Update the disk copy
				ncdf_control, ncdid, /sync

		endif else begin


			;\\ Create a new file
				ncdid = ncdf_create(fname, /clobber)
				return_id = ncdid

			;\\ Create some dimensions
				chan_dim_id = ncdf_dimdef(ncdid, 'Channel', nchannels)
				zone_dim_id = ncdf_dimdef(ncdid, 'Zone',    nzones)
				time_dim_id = ncdf_dimdef(ncdid, 'Time',    /unlimited)
				rid 		= ncdf_dimdef(ncdid, 'Rings', 	n_elements(data.zone_sectors)+1)
				rid2 		= ncdf_dimdef(ncdid, 'Rings2', 	n_elements(data.zone_sectors))

				bdate = bin_date(systime(/ut))
				date = string(bdate(2)) + '/' + string(bdate(1)) + '/' + string(bdate(0))

				xdim_id = ncdf_dimdef(ncdid, 'XDim',  data.x_pix/data.x_bin)
				ydim_id = ncdf_dimdef(ncdid, 'YDim',  data.y_pix/data.y_bin)

			;\\ Create the global attributes
				ncdf_attput, ncdid, /global, 'Start_Date_UT',date,  	       /char
				ncdf_attput, ncdid, /global, 'Site',      	 header.site,      /char
				ncdf_attput, ncdid, /global, 'Site_code', 	 header.site_code, /char
				ncdf_attput, ncdid, /global, 'Latitude',  	 header.latitude,  /float
				ncdf_attput, ncdid, /global, 'Longitude', 	 header.longitude, /float
				ncdf_attput, ncdid, /global, 'Operator',  	 header.operator,  /char
				ncdf_attput, ncdid, /global, 'Comment',   	 header.comment,   /char
				ncdf_attput, ncdid, /global, 'Software',  	 header.software,  /char

			;\\ Create the variables
				id = ncdf_vardef  (ncdid, 'Start_Time',      time_dim_id, /long)
		       	id = ncdf_vardef  (ncdid, 'End_Time',        time_dim_id, /long)
    		   	id = ncdf_vardef  (ncdid, 'Number_Scans',    time_dim_id, /short)
       			id = ncdf_vardef  (ncdid, 'X_Center',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Y_Center',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Cam_Temp',        time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'Cam_Gain',        time_dim_id, /short)
      			id = ncdf_vardef  (ncdid, 'Cam_Exptime',     time_dim_id, /float)
      			id = ncdf_vardef  (ncdid, 'X_Bin',             	  /short)
      			id = ncdf_vardef  (ncdid, 'Y_Bin',                /short)
     			id = ncdf_vardef  (ncdid, 'Gap',                  /float)
       			id = ncdf_vardef  (ncdid, 'Nm_Per_Step',     time_dim_id, /float)
       			id = ncdf_vardef  (ncdid, 'Scan_Channels',        /short)
       			id = ncdf_vardef  (ncdid, 'Gap_Refractive_Index', /float)
       			id = ncdf_vardef  (ncdid, 'Zone_Radii',      rid, /float)
       			id = ncdf_vardef  (ncdid, 'Zone_Sectors',    rid2, /byte)
				id = ncdf_vardef  (ncdid, 'Wavelength',      	  /float)
				id = ncdf_vardef  (ncdid, 'Leg1_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg2_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg3_Start_Volt',  time_dim_id, /short)
				id = ncdf_vardef  (ncdid, 'Leg1_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Leg2_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Leg3_Offset', 	  	  /float)
				id = ncdf_vardef  (ncdid, 'Phasemap', 	  	  [xdim_id, ydim_id], /long)
				id = ncdf_vardef  (ncdid, 'Spectra', [zone_dim_id, chan_dim_id, time_dim_id], /long)
				id = ncdf_vardef  (ncdid, 'Accumulated_Image', [xdim_id, ydim_id, time_dim_id], /long)

			;\\ Write the attributes
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Start_Time'),           'Units', 'Julian seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'End_Time'),             'Units', 'Julian seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Number_Scans'),         'Units', 'Etalon scans', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Zone_Radii'),           'Units', 'Zone ring radii percent fov', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Zone_Sectors'),         'Units', 'Sectors per ring', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Center'),             'Units', 'Image pixel number', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Center'),             'Units', 'Image pixel number', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Temp'),             'Units', 'Degrees', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Gain'),             'Units', 'Dimensionless', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Cam_Exptime'),          'Units', 'Seconds', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'X_Bin'), 	           'Units', 'Image x binning in pixels', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),     	       'Units', 'Image y binning in pixels', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Gap'),                  'Units', 'mm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Nm_Per_Step'),          'Units', 'nm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),        'Units', 'Etalon steps per interference order', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Gap_Refractive_Index'), 'Units', 'Dimensionless', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Wavelength'),   		   'Units', 'nm', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg1_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg2_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg3_Start_Volt'),      'Units', 'Digital voltage', /char
       			ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg1_Offset'),   	   'Units', 'Dimensionless', /char
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg2_Offset'),   	   'Units', 'Dimensionless', /char
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Leg3_Offset'),   	   'Units', 'Dimensionless', /char
				ncdf_attput, ncdid, ncdf_varid(ncdid, 'Phasemap'),   	   	   'Units', 'Scan Channels', /char
                ncdf_attput, ncdid, ncdf_varid(ncdid, 'Spectra'),              'Units', 'Camera digital units', /char
                ncdf_attput, ncdid, ncdf_varid(ncdid, 'Accumulated_Image'),    'Units', 'Camera digital units', /char

				ncdf_control, ncdid, /endef

			;\\ Write the static variables
				ncdf_varput, ncdid, ncdf_varid(ncdid, 'X_Bin'),	                data.x_bin
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Y_Bin'),                 data.y_bin
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Gap'),                   data.gap
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Scan_Channels'),         data.scan_channels
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Gap_Refractive_Index'),  data.gap_refractive_index
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Wavelength'),  		    data.wavelength
      			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg1_Offset'),  		    data.leg1_offset
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg2_Offset'),  		    data.leg2_offset
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Leg3_Offset'),  		    data.leg3_offset
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Phasemap'),  		    data.phasemap
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Zone_Radii'),            data.zone_radii
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Zone_Sectors'),          data.zone_sectors
       			ncdf_varput, ncdid, ncdf_varid(ncdid, 'Zone_Sectors'),          data.zone_sectors

			;\\ Update the disk copy
				ncdf_control, ncdid, /sync

		endelse

END_WRITE_SPECTRA_NETCDF:
end
