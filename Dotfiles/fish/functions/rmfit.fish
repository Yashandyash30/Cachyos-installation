function rmfit
    distrobox enter astro-box -- bash -c "
        cd ~/Downloads/Programs/rmfit_v432
        export IDL_DIR=\$PWD/idl81
        
        # Bypass hardware GPU drivers entirely
        export LIBGL_ALWAYS_SOFTWARE=1
        
        # Force the software renderer
        export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libOSMesa.so.8
        
        # Force the classic X11 visual
        export XLIB_SKIP_ARGB_VISUALS=1
        
        # Launch IDL
        ./idl81/bin/idl -rt=rmfit.sav
    "
end
