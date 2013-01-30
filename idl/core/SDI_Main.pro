;\\ Code formatted by DocGen


;\D\<Handle widget events. These are rerouted to the console's event handler.>
pro Handle_Event, event  ;\A\<Widget event structure>

	COMMON Console_Share, info

	info.console -> Event_Handler, event

end

;\D\<Handle widget destroy events. These are rerouted to the console's kill handler.>
pro Kill_Entry, id  ;\A\<Widget id>

	COMMON Console_Share, info

	info.console -> Kill_Handler, id

end

;\D\<Wrapper to get console data structure.>
function Get_Console_Data

	COMMON Console_Share, info

	return, info.console -> get_console_data()
end

;\D\<Error handler.>
pro Handle_Error, error  ;\A\<Error recieved>

	COMMON Console_Share, info

	print, 'THERE WAS AN ERROR! ID: ', error
	print, 'TIME: ' + systime()
	print,  'MESSAGE: ', !ERROR_STATE.MSG
	obj_destroy, info.console
	stop

end

;\D\<SDI entry point, called with a settings file, optional schedule and optional mode.>
pro SDI_Main, settings=settings, $   ;\A\<Settings file (required)>
              schedule=schedule, $   ;\A\<Schedule file (required if mode is "auto")>
              mode=mode              ;\A\<String mode, "auto" or "manual", defaults to "manual">

	COMMON Console_Share, info

	console = obj_new('XDIConsole', settings = settings, schedule = schedule, mode = mode)

	info = {console:console}

end
