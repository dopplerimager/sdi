
;\\ Use md5sums to get the checksum for the given file
function get_md5_checksum, file, exe=exe

	if not keyword_set(exe) then exe = 'md5sums'
	cmd = exe + ' -b -n ' + file
	spawn, cmd, result
	line = result[n_elements(result)-1]
	parts = strsplit(line, ' ',/extract)

	return, parts[1]
end