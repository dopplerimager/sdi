
function Get_Names, path_list

;\\ Make a list of the module names

	nmods = n_elements(path_list)

	name_list = strarr(nmods)

	for n = 0, (nmods - 1) do begin

		pos = strlen(path_list(n)) - 13
		s = strmid(path_list(n), pos, 1)
		while s ne '\' do begin
			pos = pos - 1
			s = strmid(path_list(n), pos, 1)
		endwhile

		nchars = strlen(path_list(n)) - 13 - (pos - 1)
		name_list(n) = strmid(path_list(n), pos + 4, nchars - 4)

	endfor

return, name_list

end