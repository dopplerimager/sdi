;\\ Code formatted by DocGen

;\D\<Initialize the CameraTest plugin.>
function SDICameraTest::init, restore_struc=restore_struc, $   ;\A\<Restored settings>
                           data=data                        ;\A\<Misc data from the console>

	self.need_timer = 0
	self.need_frame = 0
	self.manager 	= data.manager
	self.console 	= data.console
	self.palette	= data.palette
	self.obj_num 	= string(data.count, format = '(i0)')

	if data.recover eq 1 then begin
		;\\ Saved settings
		xoffset	= restore_struc.geometry.xoffset
		yoffset	= restore_struc.geometry.yoffset
	endif else begin
		;\\ Default settings
		xoffset	= 100
		yoffset	= 100
	endelse

	base = widget_base(xoffset = xoffset, yoffset = yoffset, mbar = menu, $
					   title = 'CameraTest', group_leader = leader, col=1)
	info = self->format_caps(self->query_camera())

	list = widget_list(base, value=info, ys=n_elements(info) , font='Ariel*18*Bold', uval={tag:'list_event'})

	self.id = base

	widget_control, base, /realize

	return, 1

end


;\D\<A dummy for gui list events.>
pro SDICameraTest::list_event, event
end


;\D\<Query the camera, return a capabilities structure.>
function SDICameraTest::query_camera

	dll = (get_console_data()).misc.dll_name
	result = get_error(call_external(dll, 'uAbortAcquisition'))

	no_camera = 0
	numADChannels = -1
	res = 'NumADChannels: ' + get_error(call_external(dll, 'uGetNumberADChannels', numAdChannels))

	;\\ GET THE BIT DEPTHS FOR EACH AD CHANNEL
	if numADChannels gt 0 then begin
		bitDepths = intarr(numADChannels)
		for adIndex = 0, numADChannels - 1 do begin
			depth = 0
			res = [res, 'BitDepth: ' + get_error(call_external(dll, 'uGetBitDepth', adIndex, depth))]
			bitDepths[adIndex] = depth
		endfor
	endif else begin
		bitDepths = -1
	endelse

	if total(bitdepths) eq 0 then begin
		;\\ Probably no camera attached! Fill rest of caps with empty vals
		no_camera = 1
	endif

	;\\ AMPLIFIERS
	numAmps = -1
	res = [res, 'NumAmps: ' + get_error(call_external(dll, 'uGetNumberAmp', numAmps))]
	if numAmps gt 0 then begin
		amps = replicate({description:'', maxHSSpeed:0.0}, numAmps)
		for ampIndex = 0, numAmps - 1 do begin
			desc = " "
			for j = 0, 20 do desc += "?"

			if no_camera eq 0 then $
				res = [res, 'AmpDesc: ' + get_error(call_external(dll, 'uGetAmpDesc', ampIndex, desc))] $
					else res = [res, '']

			pts = where(byte(desc) eq byte("?"), npts)
			if npts gt 0 then desc = strmid(desc, 0, min(pts) + 1)

			maxHsspeed = 0.0
			if no_camera eq 0 then $
				res = [res, 'AmpHSSpeed: ' + get_error(call_external(dll, 'uGetAmpMaxSpeed', ampIndex, maxHsspeed))] $
					else res = [res, '']

			amps[ampIndex].description = desc
			amps[ampIndex].maxHSSpeed = maxHSSpeed
		endfor
	endif else begin
		amps = -1
	endelse

	;\\ HORIZONTAL SHIFT SPEEDS
	hsspeeds = replicate({adchannel:0, outputamp:0, numHSSpeeds:0, speeds:fltarr(10)}, 1)
	for adchannel = 0, numADChannels - 1 do begin
		for outputamp = 0, numAmps-1 do begin
			numHSSpeeds = 0
			if no_camera eq 0 then $
				res = [res, 'NumHSSpeeds: ' + get_error(call_external(dll, 'uGetNumberHSSpeeds', adchannel, outputamp, numHSSpeeds))] $
					else res = [res, '']
			speeds = fltarr(10)
			for hsindex = 0, numHSSpeeds - 1 do begin
				hsspeed = 0.0
				res = [res, 'GetHSSpeed: ' + get_error(call_external(dll, 'uGetHSSpeed', adchannel, outputamp, hsindex, hsspeed))]
				speeds[hsindex] = hsspeed
			endfor
			hsspeeds = [hsspeeds, {adchannel:adchannel, outputamp:outputamp, numHSSpeeds:numHSSpeeds, speeds:speeds}]
		endfor
	endfor
	if n_elements(hsspeeds) gt 1 then hsspeeds = hsspeeds[1:*] else hsspeeds = -1

	;\\ PREAMP GAINS
	numPreAmpGains = -1
	res = [res, 'NumPreAmpGains: ' + get_error(call_external(dll, 'uGetNumberPreAmpGains', numPreAmpGains))]
	if numPreAmpGains gt 0 then begin
		preAmpGains = fltarr(numPreAmpGains)
		for preAmpIndex = 0, numPreAmpGains - 1 do begin
			preAmpGain = 0.0
			if no_camera eq 0 then $
				res = [res, 'GetPreAmpGain: ' + get_error(call_external(dll, 'uGetPreAmpGain', preAmpIndex, preAmpGain))] $
					else res = [res, '']
			preAmpGains[preAmpIndex] = preAmpGain
		endfor
	endif else begin
		preAmpGains = -1
	endelse

	;\\ VERTICAL SHIFT SPEEDS
	numVSSpeeds = -1
	res = [res, 'GetNumVSSpeeds: ' + get_error(call_external(dll, 'uGetNumberVSSpeeds', numVSSpeeds))]
	if numVSSpeeds gt 0 then begin
		VSSpeeds = fltarr(numVSSpeeds)
		for vsIndex = 0, numVSSpeeds - 1 do begin
			vsspeed = 0.0
			if no_camera eq 0 then $
				res = [res, 'GetVSSpeeds: ' + get_error(call_external(dll, 'uGetVSSpeed', vsIndex, vsspeed))] $
					else res = [res, '']
			VSSpeeds[vsIndex] = vsspeed
		endfor
	endif else begin
		VSSpeeds = -1
	endelse

	;\\ VERTICAL SHIFT AMPLITUDES
	numVSAmplitudes = -1
	res = 'NumVSAmplitudes: ' + get_error(call_external(dll, 'uGetNumberVSAmplitudes', numVSAmplitudes))

	;\\ FASTEST RECOMMENDED VS SPEED
	recommendedVSIndex = -1
	recommendedVSSpeed = 0.0
	res = [res, 'GetRecommendedVSSpeed: ' + get_error(call_external(dll, 'uGetFastestRecommendedVSSpeed', $
		 	recommendedVSIndex, recommendedVSSpeed))]

	;\\ MAXIMUM EXPOSURE TIME
	maxExpTime = 0.0
	res = [res, 'GetMaxExpTime: ' + get_error(call_external(dll, 'uGetMaximumExposure', maxExpTime))]

	;\\ GET THE TEMPERATURE RANGE
	min_temp = 0
	max_temp = 0
	res = [res, 'GetTempRange: ' + get_error(call_external(dll, 'uGetTemperatureRange', min_temp, max_temp))]
	tempRange = [min_temp, max_temp]

	;\\ GET DETECTOR PIXELS, X AND Y
	xpix = 0
	ypix = 0
	res = [res, 'GetPixels: ' + get_error(call_external(dll, 'uGetDetector', xpix, ypix))]
	pixels = [xpix, ypix]

	;\\ GET CIRCULAR BUFFER SIZE
	buffsize = 0L
	res = [res, 'GetBufferSize: ' + get_error(call_external(dll, 'uGetSizeOfCircularBuffer', buffsize))]

	;\\ GET SOFTWARE VERSIONS
	v0 = 0 & v1 = 0 & v2 = 0 & v3 = 0 & v4 = 0 & v5 = 0
	res = [res, 'SoftwareVersion: ' + get_error(call_external(dll, 'uGetSoftwareVersion', $
					v0, v1, v2, v3, v4, v5))]
	softwareVersion = [v0,v1,v2,v3,v4,v5]

	result = res

	out = {numADChannels:numADChannels, $
		   bitDepths:bitDepths, $
		   maxExposureTime:maxExpTime, $
		   amps:amps, $
		   preAmpGains:preAmpGains, $
		   HSSpeeds:HSSpeeds, $
		   VSSpeeds:VSSpeeds, $
		   VSRecommended:{index:recommendedVSIndex, speed:recommendedVSSpeed}, $
		   numVSAmplitudes:numVSAmplitudes, $
		   tempRange:tempRange, $
		   pixels:pixels, $
		   buffer_size:buffsize, $
		   softwareVersion:softwareVersion }

	result = get_error(call_external(dll, 'uStartAcquisition'))

	return, out
end


;\D\<Produce an array of strings to show the camera capabilities.>
function SDICameraTest::format_caps, caps

	out = ['Software Version: ' + strjoin(string(caps.softwareVersion, f='(i0)'), '.')]

	out = [out, 'Max Exposure Time: ' + string(caps.maxExposureTime, f='(f0.2)')]

	out = [out, 'Temp. Range: ' + strjoin(string(caps.temprange, f='(f0.2)'), '-')]

	out = [out, 'Output Amps: ']
	for i = 0, n_elements(caps.amps) - 1 do begin
		out = [out, '   ' + string(i, f='(i0)') + ': ' + strcompress(caps.amps[i].description) + ', Max HS Speed: ' + string(caps.amps[i].maxhsspeed, f='(f0.2)')]
	endfor

	out = [out, 'AD Channels: ' + strjoin(string(indgen(caps.numADChannels), f='(i0)') + ': ' + $
								string(caps.bitDepths, f='(i0)') + ' bits', ', ')]

	out = [out, 'PreAmp Gains:']
	for i = 0, n_elements(caps.preAmpGains) - 1 do begin
		out = [out, '   ' + string(i, f='(i0)') + ': ' + string(caps.preAmpGains[i], f='(i0)')]

	endfor

	out = [out, 'VS Amplitudes: ' + strjoin(string(indgen(caps.numVSAmplitudes), f='(i0)'), ', ')]

	out = [out, 'VS Speeds: ']
	if total(caps.VSSpeeds ne 0) then begin
		out = [out, '   ' + string(indgen(n_elements(caps.VSSpeeds)), f='(i0)') + ': ' + $
					string(caps.VSSpeeds, f='(f0.2)') + ' usecs']
	endif

	out = [out, 'Recommended VS Speed: Index=' + string(caps.VSRecommended.index, f='(i0)') + ', ' + $
				'Speed=' + string(caps.VSRecommended.speed, f='(f0.2)') + ' usecs']

	out = [out, 'HS Speeds:']
	for i = 0, n_elements(caps.HSSpeeds) - 1 do begin
		if (caps.HSSpeeds[i].numhsspeeds gt 0) then begin
			out = [out, '   AD Channel: ' + string(caps.HSSpeeds[i].adchannel, f='(i0)') + ', ' + $
						'Output Amp: ' + string(caps.HSSpeeds[i].outputamp, f='(i0)') + ', ' + $
						'Speeds: ' + strjoin( string(caps.HSSpeeds[i].speeds[0:caps.HSSpeeds[i].numhsspeeds-1], f='(i0)') + ' Mhz', ', ')]
		endif
	endfor

	return, out
end


;\D\<Get settings to save.>
function SDICameraTest::get_settings

	struc = {id:self.id, $
			 need_timer:self.need_timer, $
			 need_frame:self.need_frame, $
			 geometry:self.geometry}

	return, struc

end

;\D\<Cleanup - nothing to do.>
pro SDICameraTest::cleanup, log  ;\A\<No Doc>
end

;\D\<The CameraTest plugin queries the camera's capabilities and displays them.>
pro SDICameraTest__define

	void = {SDICameraTest, id: 0L, inherits XDIBase}

end
