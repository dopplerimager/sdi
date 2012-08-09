

;\\ General purpose convert from js to ...
function convert_js, js

	js2ymds, js, year, month, day, sec
	daynumber = ymd2dn(year, month, day)
	daynumber_string = string(daynumber, f='(i03)')
	jd0 = ymd2jd(year, month, day)

	ydn2md, year, daynumber+1, month_n, day_n
	jd0_n = ymd2jd(year, month_n, day_n)

	yy = dt_tm_mk(jd0, sec, f='y$')
	if strlen(yy) eq 1 then yy = '0' + yy
	mmdd = dt_tm_mk(jd0, sec, f='0n$0d$')
	yymmdd = yy + mmdd

	yy_n = dt_tm_mk(jd0_n, sec, f='y$')
	if strlen(yy_n) eq 1 then yy_n = '0' + yy_n
	mmdd_n = dt_tm_mk(jd0_n, sec, f='0n$0d$')
	yymmdd_n = yy_n + mmdd_n

	def_date_string = dt_tm_mk(jd0, sec)
	full_month_string = dt_tm_mk(jd0, sec, f='N$')
	part_month_string = dt_tm_mk(jd0, sec, f='n$')
	full_day_string = dt_tm_mk(jd0, sec, f='W$')
	part_day_string = dt_tm_mk(jd0, sec, f='w$')

	return, {year:year, $
			 month:month, $
			 day:day, $
			 sec:sec, $
			 dayno:daynumber, $
			 dayno_string:daynumber_string, $
			 jd:jd0, $
			 yymmdd:long(yymmdd), $
			 yymmdd_string:yymmdd, $
			 yymmdd_n_string:yymmdd_n, $
			 def_date_string:def_date_string, $
			 full_month_string:full_month_string, $
			 part_month_string:part_month_string, $
			 full_day_string:full_day_string, $
			 part_day_string:part_day_string }

end