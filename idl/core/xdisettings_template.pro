
;\D\<This file should return default initialized structures which allow the console>
;\D\<to start up and work with a basic level of functionality.>
pro xdisettings_template, etalon=etalon, $
						  camera=camera, $
						  header=header, $
						  logging=logging, $
						  misc=misc

	load_pal, culz, idl=[3,1]
    whoami, me_dir, me_file

	etalon = {eta,	  number_of_channels:128, $
						 current_channel:0, $
							 leg1_offset:1.0, $
					         leg2_offset:1.0, $
					         leg3_offset:1.0, $
							leg1_voltage:0, $
						    leg2_voltage:0, $
					        leg3_voltage:0, $
					   leg1_base_voltage:0, $
					   leg2_base_voltage:0, $
					   leg3_base_voltage:0, $
					         nm_per_step:0.07, $
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
				  					 gap:20.0, $
				  		     max_voltage:4095, $
								editable:['number_of_channels', $
										  'leg1_offset', $
										  'leg2_offset', $
										  'leg3_offset', $
										  'leg1_base_voltage', $
										  'leg2_base_voltage', $
										  'leg3_base_voltage', $
										  'nm_per_step', $
										  'nm_per_step_refresh_hours', $
										  'gap_refractive_index', $
										  'phasemap_refresh_hours', $
										  'gap', $
										  'max_voltage'] }

	camera = {cam, 	 exposure_time:0.05, $
					       read_mode:4, $
					acquisition_mode:5, $
					    trigger_mode:0, $
					    shutter_mode:1, $
				shutter_closing_time:0, $
				shutter_opening_time:10, $
				    vert_shift_speed:1, $
				    	   cooler_on:0, $
				    	 cooler_temp:-80, $
				    	    fan_mode:0, $
				    	    cam_temp:0.0, $
				    	  temp_state:'', $
				    	        xbin:1, $
				    	        ybin:1, $
				   wait_for_min_temp:0, $
				   wait_for_shutdown:0, $
				        cam_min_temp:0.0, $
				        cam_max_temp:0.0, $
				       cam_safe_temp:0.0, $
				       			gain:2, $
				       			xcen:256, $
				       			ycen:256, $
	 	       			 preamp_gain:0, $
	 	       		  baseline_clamp:1, $
	 	       		    em_gain_mode:0, $
	 	       		    vs_amplitude:0, $
	 	       		      ad_channel:0, $
	 	       		output_amplifier:0, $
	 	       				hs_speed:1, $
	 	       					xpix:512, $
	 	       					ypix:512, $
			 			    editable:['exposure_time', $
								      'read_mode', $
									  'acquisition_mode', $
								      'trigger_mode', $
								      'shutter_mode', $
									  'shutter_closing_time', $
									  'shutter_opening_time', $
							    	  'vert_shift_speed', $
							    	  'cooler_on', $
							    	  'cooler_temp', $
							    	  'fan_mode', $
							    	  'xbin', $
							    	  'ybin', $
							    	  'gain', $
				       				  'xcen', $
				       				  'ycen', $
	 	       			 			  'preamp_gain', $
	 	       		  				  'baseline_clamp', $
	 	       		    			  'em_gain_mode', $
	 	       		    			  'vs_amplitude', $
	 	       		      			  'ad_channel', $
	 	       					  	  'output_amplifier', $
	 	       						  'hs_speed', $
	 	       						  'xpix', $
	 	       						  'ypix'] }


	header = {hea,        records:0, $
				   file_specifier:'', $
				             site:'Default', $
				        site_code:'DEF', $
				  instrument_name:'Default', $
				        longitude:-145.0, $
				         latitude:60.0, $
				             year:'2013', $
				              doy:'', $
				         operator:'', $
				          comment:'', $
				         software:'', $
				            notes:replicate(string(' ', format = '(a80)'), 32), $
				   	     editable:['site', $
						           'site_code', $
						  		   'instrument_name', $
						           'longitude', $
						           'latitude', $
						           'year', $
						           'doy', $
						           'operator', $
						           'comment', $
						           'software'] }

	logging = {log,    log_directory:'', $
				    time_name_format:'', $
				      enable_logging:1, $
				       log_overwrite:0, $
				          log_append:1, $
				        ftp_snapshot:'', $
				        		 log:strarr(100), $
				         log_entries:0, $
				    	    editable:['log_directory', $
				    				  'time_name_format', $
				      				  'enable_logging', $
				       				  'log_overwrite', $
				          			  'log_append', $
				        			  'ftp_snapshot']}

;---MC mod to store more information about the type of hardware interfaces in use:
;	port_map_struc = {pms, mirror:0L, cal_source:0L, etalon:0L}
    interface_info = {ifs, number: 0L, type: 'unknown', settings: 'none'}
	port_map_struc = {pms, mirror: interface_info, cal_source: interface_info, etalon: interface_info, filter: interface_info}
	port_map_struc.etalon.type = 'Access I/O USB to Parallel'
	source_map_struc = {sms, s0:0, s1:0, s2:0, s3:0}

    misc = {mis, default_settings_path:me_dir + '..\..\setup\', $
				   screen_capture_path:me_dir + '..\..\screen_captures\', $
				        phase_map_path:me_dir + '..\..\phase_maps\', $
				         zone_set_path:me_dir + '..\..\zone_set\', $
				          spectra_path:me_dir + '..\..\spectra\', $
				              dll_name:me_dir + '..\..\bin\sdi_external.dll', $
				   timer_tick_interval:0.2, $
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
						      editable:['default_settings_path', $
								   		'screen_capture_path', $
								        'phase_map_path', $
								        'zone_set_path', $
								        'spectra_path', $
								        'dll_name', $
								   		'timer_tick_interval', $
								   		'shutdown_on_exit', $
								   		'motor_sky_pos', $
						 				'motor_cal_pos', $
						 				'port_map', $
						 				'source_map', $
						 				'snapshot_refresh_hours']}
end
