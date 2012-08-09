
;\\ Handles the log for each object which intantiates it

function XDILog::init, log_window = log_window, show_log = show_log, prog_name = prog_name, log_path = log_path, $
					   log_append = log_append,	enabled = enabled, header = header

	self.show_log  = show_log
	self.prog_name = prog_name
	self.log_path  = log_path
	self.enabled   = enabled
	self.append	   = log_append

	date_ln = bin_date(systime())
	self.curdate = string(date_ln(0),f='(i04)') + '_' + $
				   string(date_ln(1),f='(i02)') + '_' + $
				   string(date_ln(2),f='(i02)')

	if self.enabled eq 1 then begin
		log_path = self.log_path + '\' + self.curdate
		if file_test(log_path, /dir) ne 1 then begin
			file_mkdir, log_path
		endif
	endif

	if show_log eq 1 then self.log_window = log_window

	self.log(0) = prog_name + ' started: ' + systime()

	if self.enabled eq 1 then begin

		if self.append eq 1 then begin
			openw, file, log_path + '\' + self.prog_name + '_log.txt', /get_lun, /append
			if keyword_set(header) then begin
				for n = 0, n_tags(header) - 1 do begin
					if size(header.(n), /type) eq 7 then printf, file, header.(n)
				endfor
			endif
			printf, file, '	'
		endif

		if self.append eq 0 then begin
			openw, file, log_path + '\' + self.prog_name + '_log.txt', /get_lun
			if keyword_set(header) then begin
				for n = 0, n_tags(header) - 1 do begin
					if size(header.(n), /type) eq 7 then printf, file, header.(n)
				endfor
			endif
			printf, file, '	'
		endif

		printf, file, self.log(0)
		close, file
		free_lun, file
	endif

	self -> refresh

	return, 1

end


;\\ Update the log

pro XDILog::update, entry

if self.enabled eq 1 then begin

	cnt = 0
	log_path = self.log_path + '\' + self.curdate

	entry = strmid(systime(),10,9) + ' >> ' + entry

	while self.log(cnt) ne '' and cnt lt 99 do begin
		cnt = cnt + 1
	endwhile

	if cnt eq 99 then begin
		self.log = shift(self.log, -1)
		self.log(99) = entry
	endif else begin
		self.log(cnt) = entry
	endelse

	if self.show_log eq 1 and widget_info(self.log_window, /valid_id) eq 1 then begin
		widget_control, set_value = self.log, self.log_window
		widget_control, set_text_top_line = cnt - 16, self.log_window
	endif

	if self.append eq 1 then openw, file, log_path + '\' + self.prog_name + '_log.txt', /get_lun, /append
	if self.append eq 0 then openw, file, log_path + '\' + self.prog_name + '_log.txt', /get_lun
		printf, file, entry
	close, file
	free_lun, file

endif

end


;\\ Refresh the log

pro XDILog::refresh

	if self.show_log eq 1 and widget_info(self.log_window, /valid_id) eq 1 and self.enabled eq 1 then widget_control, set_value = self.log, self.log_window

end


;\\ Definition

pro XDILog__define

	void = {XDILog, log: strarr(100), log_window: 0L, prog_name:'', log_path:'', show_log:0, curdate:'', append:0, enabled:0}

end




