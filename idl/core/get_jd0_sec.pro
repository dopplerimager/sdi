;\\ Code formatted by DocGen


;\D\<Get the current julian date and the seconds into the day.>
pro get_jd0_sec, jd0, $   ;\A\<OUT: Julian date at midnight I think...>
                 sec      ;\A\<OUT: Seconds into the julian day>

	js_now = dt_tm_tojs(systime(/ut))
	js2ymds, js_now, yy, mm, dd, ss

	;js_utz = ymds2js(yy, mm, dd-1, 12.0)

	;jd0 = systime(/julian, /ut)
	;sec = js_now - js_utz

	jd0 = systime(/jul) + .5
	sec = ss

end
