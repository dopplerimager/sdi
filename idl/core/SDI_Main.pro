


;\\ Passes events from all widgets to the console event handler

pro Handle_Event, event

	COMMON Console_Share, info

	;\\ Setup the error handler
		error = 0
		catch, error
		if error ne 0 then Handle_Error, error


	info.console -> Event_Handler, event

end


;\\ Passes object (widget) destruction events back to the console destruction handler

pro Kill_Entry, id

	COMMON Console_Share, info

	;\\ Setup the error handler
		error = 0
		catch, error
		if error ne 0 then Handle_Error, error

	info.console -> Kill_Handler, id

end


;\\ Error handler

pro Handle_Error, error

	COMMON Console_Share, info
stop
	print, 'THERE WAS AN ERROR! ID: ', error
	print, 'TIME: ' + systime()
	print,  'MESSAGE: ', !ERROR_STATE.MSG
	obj_destroy, info.console

end

;\\ Main program - initiates the console

pro SDI_Main, settings = settings, schedule = schedule, mode = mode

	COMMON Console_Share, info

	;\\ Setup the error handler
		error = 0
;		catch, error
		if error ne 0 then Handle_Error, error


;	settings = 'c:\users\sdi3000\setup\conde_setup.sdi'
;	mode = 'manual'
;	schedule = 'c:\users\sdi3000\setup\red_only.txt'

	console = obj_new('XDIConsole', settings = settings, schedule = schedule, mode = mode)

	info = {console:console}

end

