;\\ Code formatted by DocGen


;\D\<No Doc>
pro XDIBase__define

	load_pal, culz, idl = [3,1]

	geoms = {wid_geo, XOFFSET:0.0, YOFFSET:0.0, XSIZE:0.0, YSIZE:0.0, SCR_XSIZE:0.0, SCR_YSIZE:0.0, DRAW_XSIZE:0.0, DRAW_YSIZE:0.0, $
	 			MARGIN:0.0, XPAD:0.0, YPAD:0.0, SPACE:0.0 }

;	logging = {log,    log_directory:'', $
;				    time_name_format:'', $
;				      enable_logging:0, $
;				       log_overwrite:0, $
;				          log_append:0, $
;				        ftp_snapshot:'', $
;				        		 log:strarr(100), $
;				         log_entries:0, $
;				    	    editable:[0,1,2,3,4,5]}

	void = {XDIBase, obj_num:'',  $
					geometry:geoms, $
			      need_frame:0, $
				  need_timer:0, $
				  		auto:0, $
				  	 palette:culz, $
				     manager:obj_new(), $
				     console:obj_new()  }

end
