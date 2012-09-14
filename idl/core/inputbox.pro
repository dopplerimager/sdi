
pro inputBox_event, event

	common InputBoxShared, outvar

	widget_control, get_uval = uval, event.id

	if uval.type eq "cancel" then begin
		outvar = uval.invar
		widget_control, uval.base, /destroy
		return
	endif

	if uval.type eq "input" then begin
		widget_control, get_value = val, event.id
	endif

	if uval.type eq "accept" then begin
		widget_control, get_value = val, uval.input
	endif

	intype = size(uval.invar, /type)
	outvar = fix(val, type=intype)
	widget_control, uval.base, /destroy

end

function inputBox, var, parent=parent, title=title, font=font

	common InputBoxShared, outvar

	if not keyword_set(font) then font = "TimesBold*18"

	if keyword_set(parent) then begin
		if widget_info(parent, /valid_id) then begin
			base = widget_base(group_leader = parent, col=1, title=title)
		endif
	endif else begin
		base = widget_base(group_leader = parent, col=1, title=title)
	endelse

	if (size(var, /type) ge 1 and size(var, /type) le 3) or $
	   (size(var, /type) ge 12 and size(var, /type) le 15) then begin
		stringvar = string(var, format = "(i0)")
	endif

	if size(var, /type) eq 4 or size(var, /type) eq 5 then begin
		stringvar = string(var, format = "(f0.8)")
	endif

	if size(var, /type) eq 7 then begin
		stringvar = var
	endif

	base0 = widget_base(base, col=1)
	label = widget_label(base0, value = "Type Value and Hit Enter (" + size(var, /tname) + "):", font=font)
	input = widget_text(base0, value = stringvar, font=font, /edit, uval = {type:"input", invar:var, base:base})
	base1 = widget_base(base0, col=2, /align_center)
	button = widget_button(base1, value = "Accept", font=font, uval = {type:"accept", invar:var, base:base, input:input})
	button = widget_button(base1, value = "Cancel", font=font, uval = {type:"cancel", invar:var, base:base, input:input})

	widget_control, base, /realize
	widget_control, input, /input_focus, set_text_select = [0, strlen(stringvar)]
	xmanager, "inputBox", base, event_handler = "inputBox_event"

	return, outvar[0]

end