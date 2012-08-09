
function get_paths

;\\ Extract paths from !path to search for SDI modules

str = '' & paths = strarr(1) & this_path = '' & path_cnt = 0

for pos = 0, (strlen(!path) - 1) do begin

	str = strmid(!path, pos, 1)

    if str ne ';' then begin
	    this_path = this_path + str
    endif

    if str eq ';' or pos eq (strlen(!path) - 1) then begin
    	if path_cnt eq 0 then begin
 			paths(0) = this_path
 			path_cnt = path_cnt + 1
 			this_path = ''
		endif else begin
			path_cnt = path_cnt + 1
			temp = temporary(paths)
			paths = strarr(path_cnt)
			paths(0:path_cnt-2) = temp
			paths(path_cnt-1) = this_path
			this_path = ''
		endelse
	endif

endfor

return, paths

end