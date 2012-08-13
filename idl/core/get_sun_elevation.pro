;\\ Code formatted by DocGen


;\D\<Get the current sun elevation for a given latitude and longitude.>
function get_sun_elevation, lat, $   ;\A\<Geographic latitude>
                            lon      ;\A\<Geographic longitude>

	time = bin_date(systime(/ut))

	ut_fraction = (time(3)*3600. + time(4)*60. + time(5)) / 86400.

	sidereal_time = lmst(systime(/julian), ut_fraction, 0) * 24.

	sunpos, systime(/julian), RA, Dec

	sun_lat = Dec
	sun_lon = RA - (15. * sidereal_time)

	ll2rb, lon, lat, sun_lon, sun_lat, range, azimuth

	sun_elevation = refract(90 - (range * !radeg))

	return, sun_elevation

end
