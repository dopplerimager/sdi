
pro Get_Ephemeris, save_name=save_name, safe_sea=safe_sea, lat=lat, lon=lon, timeres=timeres, start_stop_times=start_stop_times, $
				   get_sea = get_sea

	if not keyword_set(lat) then lat = -67.6
	if not keyword_set(lon) then lon = 62.87
	if not keyword_set(timeres) then timeres = 1.
	if not keyword_set(safe_sea) then safe_sea = 0.
	if not keyword_set(save_name) then save_name = 'c:\observing_times.png'


	;\\ Get current time information, plus julian seconds at 00 UT on this day:
    	jsnow = dt_tm_tojs(systime())
    	js2ymds, jsnow, yy, mm, dd, ss
    	jsutz = ymds2js(yy, mm, dd, 0)
    	date = string(bin_date(systime()), f='(i2.2)')
    	date_str = date(2) + '/' + date(1) + '/' + string(yy, f='(i0)')
	    time_str = date(3) + ':' + date(4) + ':' + date(5)
	    start_hour = ss/3600.



	;\\ Get moon alt, azi:
       	ut     = findgen(1+24*60/timeres)*timeres/(24*60); UT in days.
       	jd     = systime(/julian) - (jsnow - jsutz)/86400. + ut
       	moonpos, jd, ra, dec, dis, geolong, geolat
       	st     = lmst(systime(/julian) - (jsnow - jsutz)/86400., ut, 0)*24
       	lunlat = dec
       	lunlng = ra - 15.*st
       	ll2rb, lon, lat, lunlng, lunlat, rr, lunazi
       	lunalt = refract(90-rr*!radeg)
       	luntst = lunalt

	;\\ Get sun alt, azi:
       	sunpos,  jd, ra, dec
       	sunlat = dec
       	sunlng = ra - 15.*st
       	ll2rb, lon, lat, sunlng, sunlat, rr, sunazi
       	sunalt = refract(90-rr*!radeg)
       	sea    = sunalt

	;\\ Find safe times
		safe_times = where(sea lt safe_sea, nsafe)

	;\\ Get the start and stop times, one for each observing period
		;\\ First find number of observing periods (continuous blocks of safe times)
			ut = ut*24. + start_hour

			i = 1
			nbreaks = 0
			for i = 1, nsafe - 1 do begin
				if (safe_times(i) - safe_times(i-1)) ne 1 then nbreaks = nbreaks + 1
			endfor

			start_stop_times = fltarr(nbreaks+1,2)		;\\ 0-Start time, 1-Stop time, in julian seconds
			start_stop_times(0,0) = ymds2js(yy, mm, dd, ut(safe_times(0))*3600.)
			period = 0

			for i = 1, nsafe - 1 do begin
				if safe_times(i) - safe_times(i-1) ne 1 then begin
					start_stop_times(period,1) = ymds2js(yy, mm, dd, ut(safe_times(i-1))*3600.)
					period = period + 1
					start_stop_times(period,0) = ymds2js(yy, mm, dd, ut(safe_times(i))*3600.)
				endif
			endfor

			start_stop_times(period,1) = ymds2js(yy, mm, dd, ut(safe_times(nsafe-1))*3600.)


	;\\ Make a plot
		loadct, 39, /silent

		x = fltarr(nsafe,2)
		y = fltarr(nsafe,2)

		ymax = (max(sea) > max(lunalt))
		ymin = (min(sea) < min(lunalt))

		x(*,0) = ut(safe_times(*))
		x(*,1) = ut(safe_times(*))
		y(*,0) = ymin
		y(*,1) = ymax

		window, /free
		windex = !D.WINDOW

		plot, ut, sea, color=0, back=255, thick=2, yrange=[ymin-10, ymax+10], /nodata, /ystyle, /xstyle, $
			  ytitle = 'Elevation Angle (degrees)', xtitle = 'Time (UT hours)', title = 'Sun and Moon Elevations for ' + date_str + $
			  ', starting ' + time_str, charsize = 1.2, charthick = 1.5
		for n = 0, nsafe - 1 do begin
			plots, [x(n,0), x(n,1)], [y(n,0), y(n,1)], color = 192, /data
		endfor
		plot, ut, sea, color=0, back=255, thick=2, yrange=[ymin-10, ymax+10], /nodata, /noerase, /ystyle, /xstyle, $
			  ytitle = 'Elevation Angle (degrees)', xtitle = 'Time (UT hours)', title = 'Sun and Moon Elevations for ' + date_str + $
			  ', starting ' + time_str, charsize = 1.2, charthick = 1.5

		for n = 0, period do begin
			plots, [start_stop_times(n,0), start_stop_times(n,0)], [ymin, ymax], color=143, thick=3
			plots, [start_stop_times(n,1), start_stop_times(n,1)], [ymin, ymax], color=0, thick=3
		endfor

		oplot, ut, sea, color=254, thick=3
		oplot, ut, lunalt, color=64, thick=3
		oplot, [ut(0), ut(n_elements(ut)-1)], [0, 0], col=0, thick=2, line=1

		xyouts, /data, start_hour + 4, ymin - 6, '____', color = 64, charsize = 1.2, charthick=3
		xyouts, /data, start_hour + 5.5, ymin - 6.8, 'Moon', color = 64, charsize = 1.5, charthick=1.5
		xyouts, /data, start_hour + 9, ymin - 6, '____', color = 254, charsize = 1.2, charthick=3
		xyouts, /data, start_hour + 10.5, ymin - 6.8, 'Sun', color = 254, charsize = 1.5, charthick=1.5
		plots, start_hour + 14.5, ymin - 6, psym=6, col=192, thick=15, symsize=1.5
		xyouts, /data, start_hour + 15.3, ymin - 6.8, 'Observation Times', col = 0, charsize = 1.2, charthick=1.5

		tvlct, r, g, b, /get
		pic = tvrd(/true)
		write_png, save_name, pic

		wdelete, windex

END_EPHEMERIS:
end