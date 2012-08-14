;\\ Code formatted by DocGen


;\D\<Initialize the plugin list with the id and object reference of the console.>
function XDIWidgetReg::init, ref=ref, $   ;\A\<Console object reference>
                             id=id        ;\A\<Console widget id>

	self.id = id
	self.ref = ref
	self.type = 'Console Base'
	self.controller = 0
	self.store = 0
	self.next =	ptr_new({id: 0L, type: '', ref: obj_new(), store:0, need_timer:0, need_frame:0, controller: 0, next: ptr_new()})

	return, 1

end

;\D\<Add a plugin to the list.>
pro XDIWidgetReg::register, id, $      ;\A\<Widget id of the plugin's main window>
                            ref, $     ;\A\<Object reference for this instance of the plugin>
                            type, $    ;\A\<Plugin type (string name)>
                            store, $   ;\A\<Flag to indicate whether or not to save plugin settings>
                            timer, $   ;\A\<Flag to indicate this plugin needs to recieve timer events>
                            frame      ;\A\<Flag to indicate this plugin needs to recieve frame events>

	current = self.next

	while ptr_valid(current) do begin

		last = current
		current = (*current).next

	endwhile

	(*last).id = id
	(*last).ref = ref
	(*last).type = type
	(*last).store = store
	(*last).need_timer = timer
	(*last).need_frame = frame
	(*last).controller = 0
	(*last).next = ptr_new({id: 0L, type: '', ref: obj_new(), store:0, need_timer:0, need_frame:0, controller: 0, next: ptr_new()})

end

;\D\<From a widget id, return the object reference of the plugin.>
function XDIWidgetReg::match_register_ref, id  ;\A\<Widget if of the plugin's main window>

	current = self.next
	if self.id eq id then return, self.ref

	while ptr_valid(current) do begin

		if (*current).id eq id then return, (*current).ref
		current = (*current).next

	endwhile

	return, 0

end

;\D\<From a widget id, return the need\_frame field of the plugin.>
function XDIWidgetReg::match_register_timer, id  ;\A\<Widget if of the plugin's main window>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).id eq id then return, (*current).need_timer
		current = (*current).next

	endwhile

	return, 0

end

;\D\<From a widget id, return the need\_frame field of the plugin.>
function XDIWidgetReg::match_register_frame, id  ;\A\<Widget if of the plugin's main window>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).id eq id then return, (*current).need_frame
		current = (*current).next

	endwhile

	return, 0

end

;\D\<From a widget id, return the plugin type.>
function XDIWidgetReg::match_register_type, id  ;\A\<Widget id of the plugin's main window>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).id eq id then return, (*current).type
		current = (*current).next

	endwhile

	return, 0

end

;\D\<From a plugin type, return the object reference of the plugin.>
function XDIWidgetReg::match_register_from_type, type  ;\A\<String type of the plugin>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).type eq type then return, (*current).ref
		current = (*current).next

	endwhile

	return, obj_new()

end

;\D\<Given a widget id, return the value of the store field for the corresponding plugin.>
function XDIWidgetReg::match_register_store, id  ;\A\<Widget id of the plugin's main window>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).id eq id then return, (*current).store
		current = (*current).next

	endwhile

	return, 2

end

;\D\<Print out info about the list of plugins.>
pro XDIWidgetReg::print_register

	current = self.next
	print, self.id, self.ref, self.type

	while ptr_valid(current) do begin

		print, (*current).id, (*current).ref, (*current).type, (*current).store, (*current).controller
		current = (*current).next

	endwhile

end

;\D\<Generate a structure whose fields are arrays, one element for each plugin, containing>
;\D\<the plugin info.>
function XDIWidgetReg::generate_list

	current = self.next

	num = self -> count_objects()

	if num gt 0 then begin

		struc = {id: lonarr(num), type: strarr(num), store: intarr(num), need_timer: intarr(num), controller:intarr(num), $
				 ref: objarr(num), need_frame: intarr(num)}

		for x = 0, num - 1 do begin

			struc.id(x) = (*current).id
			struc.ref(x) = (*current).ref
			struc.type(x) = (*current).type
			struc.store(x) = (*current).store
			struc.need_timer(x) = (*current).need_timer
			struc.need_frame(x) = (*current).need_frame
			struc.controller(x) = (*current).controller

			current = (*current).next

		endfor

		return, struc

	endif

	return, 0

end

;\D\<Count the number of plugins, and return the count.>
function XDIWidgetReg::count_objects

	current = self.next

	cnt = -1

	while ptr_valid(current) do begin

		cnt = cnt + 1
		current = (*current).next

	endwhile

	return, cnt

end

;\D\<I have no idea what this does, and it does not appear to be called anywhere in the>
;\D\<SDI code base, so it is probably a holdover from an early version.>
pro XDIWidgetReg::set_control, id, $        ;\A\<No Doc>
                               ref, $       ;\A\<No Doc>
                               control      ;\A\<No Doc>

	current = self.next

	while ptr_valid(current) do begin

		if (*current).id eq id and (*current).ref eq ref then begin
			(*current).controller = control
		endif

		current = (*current).next

	endwhile

end

;\D\<Remove a plugin from the list.>
pro XDIWidgetReg::delete_instance, id  ;\A\<Widget id of the plugin to remove>

		current = self.next
    	cnt = 0

    	while ptr_valid(current) do begin

    	 cnt = cnt + 1

    	 if (*current).id eq id then begin

		  ;\\ If its the first object (not including the console), delete
		  ;\\ and check if the pointer from this element is valid, then set
		  ;\\ self.next to that list element

		  if cnt eq 1 then begin

	       if ptr_valid(((*current).next)) then begin
			temp_ptr = (*current).next
			ptr_free, self.next
	        self.next = temp_ptr
	        break
	       endif else begin
			ptr_free, self.next
			self.next = ptr_new({id:0L, type:'', ref:obj_new(), store:0, need_timer:0, need_frame:0, controller: 0, next:ptr_new()})
			break
		   endelse

		  endif else begin

		   if ptr_valid(((*current).next)) then begin
			temp_ptr = (*current).next
			ptr_free, (*last).next
    	    (*last).next = temp_ptr
    	    break
    	   endif else begin
			ptr_free, (*last).next
			(*last).next = ptr_new({id:0L, type:'', ref:obj_new(), store:0, need_timer:0, need_frame:0, controller: 0, next:ptr_new()})
 			break
		   endelse

		  endelse

	 	endif

	 	last = current
     	current = (*current).next

    	endwhile

end

;\D\<This implements the ability of plugins to save their settings, to be restored>
;\D\<next time they are opened.>
pro XDIWidgetReg::save_settings, path, $    ;\A\<The settings save path>
                                 id, $      ;\A\<The widget id of the plugin's main window>
                                 owner, $   ;\A\<String name of the plugin>
                                 ref        ;\A\<Object reference to the plugin>

	;\\ First get the generic settings for the object

	geom = widget_info(id, /geometry)

	geom.ysize = geom.ysize - 20

	;\\ Retrieve the current settings

	save_struc = ref -> get_settings()

	;\\ Update the generic settings

	save_struc.geometry = geom

	;\\ Save the struc under the modules name 'Vidshow', 'Spectrum', etc.

	save, filename = path + owner + '.sdi', save_struc

end

;\D\<This class manages plugins, by storing their object references and names in a linked list>
;\D\<and managing that list.>
pro XDIWidgetReg__define

	void = {XDIWidgetReg, id: 0L, type: '', ref: obj_new(), store: 0, need_timer: 0, need_frame:0, controller: 0, next: ptr_new()}

end
