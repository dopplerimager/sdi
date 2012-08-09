
;\\ Returns the julian date at 0:00 for this UT date and seconds since jd0

pro get_jd0_sec, jd0, sec

	js_now = dt_tm_tojs(systime(/ut))
	js2ymds, js_now, yy, mm, dd, ss

	;js_utz = ymds2js(yy, mm, dd-1, 12.0)

	;jd0 = systime(/julian, /ut)
	;sec = js_now - js_utz

	jd0 = systime(/jul) + .5
	sec = ss

end