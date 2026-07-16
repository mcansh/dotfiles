# Vite+ generates a complete Fish script. Let Fish autoload it only when the
# user first requests `vp` completions instead of running Vite+ at startup.
command -q vp; and VP_COMPLETE=fish command vp | source
