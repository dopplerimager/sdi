
;\\ Use md5sums to get the checksum for the given file
function get_md5_checksum, exe, file

	cmd = exe + ' -b ' + file
	spawn, cmd, result
	line = result[n_elements(result)-1]
	parts = strsplit(line, ' ',/extract)

	return, parts[1]
end