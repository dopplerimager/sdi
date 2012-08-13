;\\ Code formatted by DocGen


;\D\<Handle widget events. These are rerouted to the console's event handler.>
pro Handle_Event, event  ;\A\<Widget event structure>

	COMMON Console_Share, info

	;\\ Setup the error handler
		error = 0
		catch, error
		if error ne 0 then Handle_Error, error


	info.console -> Event_Handler, event

end

;\D\<Handle widget destroy events. These are rerouted to the consoles kill handler.>
pro Kill_Entry, id  ;\A\<Widget id>

	COMMON Console_Share, info

	;\\ Setup the error handler
		error = 0
		catch, error
		if error ne 0 then Handle_Error, error

	info.console -> Kill_Handler, id

end

;\D\<Error handler.>
pro Handle_Error, error  ;\A\<Error recieved>

	COMMON Console_Share, info
stop
	print, 'THERE WAS AN ERROR! ID: ', error
	print, 'TIME: ' + systime()
	print,  'MESSAGE: ', !ERROR_STATE.MSG
	obj_destroy, info.console

end

;\D\<SDI entry point, called with a settings file, optional schedule and optional mode.>
pro SDI_Main, settings=settings, $   ;\A\<Settings file (required)>
              schedule=schedule, $   ;\A\<Schedule file (required if mode is "auto")>
              mode=mode              ;\A\<String mode, "auto" or "manual", defaults to "manual">

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
