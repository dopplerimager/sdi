SDI
------------

This repo contains the common IDL code for running the SDI, plus things like DLL's, 
devcon and pstools, the watchdog scripts, driver stuff for the Faulhaver motors, 
Andor camera, MOXA usb hub, etc. 

The standard directory to place this tree is in c:\users\sdi3000\. Some stuff (like
the watchdog scripts) assume this directory structure. Additional directories need to be 
created on the target machine, depending on the settings file, for example the 
following directories are expected by the console and read from the settings file:

* DEFAULT_SETTINGS_PATH - where to look for and store plugin settings (geometry, etc.)             
* SCREEN_CAPTURE_PATH - to store screen caps                   
* PHASE_MAP_PATH - where to store phase maps (these are also saved in the NETCDF files
* ZONE_SET_PATH - where to look for zone settings files 
* SPECTRA_PATH - where to store the data
* DLL_NAME  - path and filename of the SDI_EXTERNAL.dll

Note also that the watchdog scripts will need to be updated on the target machine to 
make sure their paths are correct. In addition, the first time that some of the pstools
executables are run they will ask you to agree with the SYSINTERNALS SOFTWARE LICENSE TERMS
and execution will halt until you do this manually. Each executable in pstools will ask
for separate confirmation which is annoying. Currently, I think that only pskill is used 
by the SDI software, so it is worth running this executable at least, to get the license
dialog out of the way for future use. 

 
