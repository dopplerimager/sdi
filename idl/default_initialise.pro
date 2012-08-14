
;\\ CLEANUP ROUTINES
pro Default_cleanup, misc, console

	console->log, 'Cleanup', 'InstrumentSpecific', /display

end

;\\ MIRROR ROUTINES
pro Default_mirror,  drive_to_pos = drive_to_pos, $
				  home_motor = home_motor, $
				  read_pos = read_pos,  $
				  misc, console

	read_pos = 0
	console->log, 'Mirror', 'InstrumentSpecific', /display
end



;\\ CALIBRATION SWITCH ROUTINES
pro Default_switch, source, $
				  	  misc, console


	console->log, 'Cal Switch', 'InstrumentSpecific', /display

end



;\\ FILTER SELECT ROUTINES
pro Default_filter, filter_number, $
					  log_path = log_path, $
				  	  misc, console

	console->log, 'Filter', 'InstrumentSpecific', /display

end


;\\ ETALON LEG ROUTINES
pro Default_etalon, dll, $
				  leg1_voltage, $
				  leg2_voltage, $
				  leg3_voltage, $
				  misc, console

	console->log, 'Etalon', 'InstrumentSpecific', /display

end


;\\ IMAGE POST PROCESSING ROUTINES
pro Default_imageprocess, image

end

;\\ INITIALISATION ROUTINES
pro Default_initialise, misc, console

	console->log, '** Default Init **', 'InstrumentSpecific', /display

end
