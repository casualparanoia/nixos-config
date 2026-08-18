local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Always use Nushell natively (no matter how you open a tab)
config.default_prog = { 'nu' }

-- 2. Completely hide WezTerm's built-in tab bar to let Niri handle tabs
-- config.enable_tab_bar = false

-- 3. Remove WezTerm's titlebar and borders (Niri provides its own window borders)
config.window_decorations = "NONE"

-- Make the cursor a blinking beam (bar) instead of a block
config.default_cursor_style = 'BlinkingBar'

-- Optional: How fast the cursor blinks (in milliseconds). Default is 500.
config.cursor_blink_rate = 400

-- Optional: Make the beam slightly thicker (default is 1px)
config.cursor_thickness = '1.5px'

-- Disable the annoying terminal bell sound
--config.audible_bell = 'Disabled'

--------Theming--------

-- Set a built-in theme
config.color_scheme = 'astromouse (terminal.sexy)'

-- Optional: Make the background slightly transparent to see your wallpaper
-- (Niri handles blur automatically if you have it enabled in your Niri config)
config.window_background_opacity = 0.90

-- Enable font ligatures (turns != into ≠, -> into →, etc.)
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

--------------PERFORMANCE-------------
-- Keep 10,000 lines of scrollback memory (default is 3,500)
config.scrollback_lines = 10000

-- Force WebGpu for modern Wayland hardware acceleration 
-- (If you experience graphical glitches, remove this line to let it fallback to OpenGL)
config.front_end = 'WebGpu'

return config
