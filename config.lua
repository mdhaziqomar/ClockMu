local Config = {}

-- ============================================================
-- NAMED THEMES
-- Each entry: display name + full colour table {R,G,B} 0.0-1.0
-- ============================================================
Config.THEMES = {
    {
        name = "Mustard Yellow",
        bg_main      = {0.071, 0.071, 0.071},
        bg_header    = {0.161, 0.133, 0.047},
        bg_panel     = {0.110, 0.095, 0.040},
        bg_row       = {0.130, 0.110, 0.045},
        bg_row_sel   = {0.698, 0.557, 0.086},
        bg_modal     = {0.090, 0.075, 0.030},
        bg_modal_hdr = {0.161, 0.133, 0.047},
        bg_btn_bar   = {0.141, 0.118, 0.043},
        accent       = {0.863, 0.706, 0.118},
        accent_dim   = {0.698, 0.557, 0.086},
        accent_glow  = {1.000, 0.851, 0.200},
        text_primary   = {1.000, 0.980, 0.900},
        text_secondary = {0.698, 0.657, 0.500},
        text_accent    = {0.863, 0.706, 0.118},
        text_disabled  = {0.400, 0.380, 0.280},
        col_enabled  = {0.863, 0.706, 0.118},
        col_disabled = {0.380, 0.360, 0.260},
        col_ringing  = {1.000, 0.400, 0.100},
        col_snooze   = {0.400, 0.700, 1.000},
    },
    {
        name = "Intense Orange",
        bg_main      = {0.071, 0.055, 0.035},
        bg_header    = {0.180, 0.090, 0.020},
        bg_panel     = {0.130, 0.072, 0.020},
        bg_row       = {0.150, 0.085, 0.025},
        bg_row_sel   = {0.800, 0.380, 0.040},
        bg_modal     = {0.100, 0.060, 0.020},
        bg_modal_hdr = {0.180, 0.090, 0.020},
        bg_btn_bar   = {0.160, 0.080, 0.022},
        accent       = {1.000, 0.490, 0.090},
        accent_dim   = {0.800, 0.380, 0.060},
        accent_glow  = {1.000, 0.650, 0.200},
        text_primary   = {1.000, 0.960, 0.920},
        text_secondary = {0.750, 0.560, 0.400},
        text_accent    = {1.000, 0.490, 0.090},
        text_disabled  = {0.420, 0.310, 0.220},
        col_enabled  = {1.000, 0.490, 0.090},
        col_disabled = {0.380, 0.280, 0.200},
        col_ringing  = {1.000, 0.200, 0.050},
        col_snooze   = {0.400, 0.700, 1.000},
    },
    {
        name = "Bloody Red",
        bg_main      = {0.075, 0.030, 0.030},
        bg_header    = {0.200, 0.040, 0.040},
        bg_panel     = {0.140, 0.035, 0.035},
        bg_row       = {0.160, 0.038, 0.038},
        bg_row_sel   = {0.750, 0.080, 0.080},
        bg_modal     = {0.110, 0.030, 0.030},
        bg_modal_hdr = {0.200, 0.040, 0.040},
        bg_btn_bar   = {0.180, 0.038, 0.038},
        accent       = {0.950, 0.180, 0.180},
        accent_dim   = {0.750, 0.120, 0.120},
        accent_glow  = {1.000, 0.380, 0.380},
        text_primary   = {1.000, 0.940, 0.940},
        text_secondary = {0.720, 0.500, 0.500},
        text_accent    = {0.950, 0.180, 0.180},
        text_disabled  = {0.420, 0.260, 0.260},
        col_enabled  = {0.950, 0.180, 0.180},
        col_disabled = {0.380, 0.200, 0.200},
        col_ringing  = {1.000, 0.050, 0.050},
        col_snooze   = {0.400, 0.700, 1.000},
    },
    {
        name = "Ocean Blue",
        bg_main      = {0.035, 0.055, 0.100},
        bg_header    = {0.040, 0.090, 0.200},
        bg_panel     = {0.035, 0.072, 0.150},
        bg_row       = {0.038, 0.080, 0.165},
        bg_row_sel   = {0.060, 0.300, 0.750},
        bg_modal     = {0.030, 0.060, 0.120},
        bg_modal_hdr = {0.040, 0.090, 0.200},
        bg_btn_bar   = {0.038, 0.082, 0.180},
        accent       = {0.150, 0.580, 1.000},
        accent_dim   = {0.100, 0.420, 0.800},
        accent_glow  = {0.400, 0.750, 1.000},
        text_primary   = {0.920, 0.960, 1.000},
        text_secondary = {0.500, 0.650, 0.800},
        text_accent    = {0.150, 0.580, 1.000},
        text_disabled  = {0.280, 0.380, 0.500},
        col_enabled  = {0.150, 0.580, 1.000},
        col_disabled = {0.200, 0.320, 0.480},
        col_ringing  = {1.000, 0.400, 0.100},
        col_snooze   = {0.200, 0.900, 0.700},
    },
    {
        name = "Forest Green",
        bg_main      = {0.035, 0.075, 0.035},
        bg_header    = {0.040, 0.160, 0.060},
        bg_panel     = {0.035, 0.120, 0.048},
        bg_row       = {0.038, 0.135, 0.052},
        bg_row_sel   = {0.060, 0.480, 0.120},
        bg_modal     = {0.030, 0.100, 0.040},
        bg_modal_hdr = {0.040, 0.160, 0.060},
        bg_btn_bar   = {0.038, 0.145, 0.056},
        accent       = {0.180, 0.820, 0.280},
        accent_dim   = {0.120, 0.620, 0.200},
        accent_glow  = {0.400, 1.000, 0.500},
        text_primary   = {0.920, 1.000, 0.930},
        text_secondary = {0.500, 0.720, 0.540},
        text_accent    = {0.180, 0.820, 0.280},
        text_disabled  = {0.280, 0.450, 0.300},
        col_enabled  = {0.180, 0.820, 0.280},
        col_disabled = {0.200, 0.400, 0.220},
        col_ringing  = {1.000, 0.400, 0.100},
        col_snooze   = {0.400, 0.700, 1.000},
    },
    {
        name = "Funky Purple",
        bg_main      = {0.060, 0.030, 0.090},
        bg_header    = {0.120, 0.040, 0.200},
        bg_panel     = {0.090, 0.035, 0.150},
        bg_row       = {0.100, 0.038, 0.165},
        bg_row_sel   = {0.380, 0.080, 0.720},
        bg_modal     = {0.075, 0.030, 0.120},
        bg_modal_hdr = {0.120, 0.040, 0.200},
        bg_btn_bar   = {0.110, 0.038, 0.180},
        accent       = {0.780, 0.300, 1.000},
        accent_dim   = {0.580, 0.200, 0.800},
        accent_glow  = {0.900, 0.500, 1.000},
        text_primary   = {0.970, 0.940, 1.000},
        text_secondary = {0.650, 0.500, 0.800},
        text_accent    = {0.780, 0.300, 1.000},
        text_disabled  = {0.400, 0.280, 0.550},
        col_enabled  = {0.780, 0.300, 1.000},
        col_disabled = {0.350, 0.200, 0.500},
        col_ringing  = {1.000, 0.150, 0.500},
        col_snooze   = {0.400, 0.700, 1.000},
    },
    {
        name = "Yoga White",
        bg_main      = {0.920, 0.915, 0.900},
        bg_header    = {0.850, 0.840, 0.820},
        bg_panel     = {0.880, 0.875, 0.860},
        bg_row       = {0.870, 0.862, 0.845},
        bg_row_sel   = {0.600, 0.780, 0.900},
        bg_modal     = {0.900, 0.895, 0.880},
        bg_modal_hdr = {0.850, 0.840, 0.820},
        bg_btn_bar   = {0.840, 0.832, 0.815},
        accent       = {0.100, 0.450, 0.800},
        accent_dim   = {0.200, 0.550, 0.850},
        accent_glow  = {0.050, 0.350, 0.700},
        text_primary   = {0.080, 0.080, 0.090},
        text_secondary = {0.380, 0.370, 0.360},
        text_accent    = {0.100, 0.450, 0.800},
        text_disabled  = {0.600, 0.590, 0.570},
        col_enabled  = {0.100, 0.650, 0.300},
        col_disabled = {0.680, 0.670, 0.650},
        col_ringing  = {0.850, 0.100, 0.100},
        col_snooze   = {0.100, 0.450, 0.800},
    },
    {
        name = "Midnight Black",
        bg_main      = {0.040, 0.040, 0.045},
        bg_header    = {0.060, 0.060, 0.068},
        bg_panel     = {0.055, 0.055, 0.062},
        bg_row       = {0.058, 0.058, 0.065},
        bg_row_sel   = {0.160, 0.160, 0.180},
        bg_modal     = {0.048, 0.048, 0.054},
        bg_modal_hdr = {0.060, 0.060, 0.068},
        bg_btn_bar   = {0.055, 0.055, 0.062},
        accent       = {0.750, 0.750, 0.800},
        accent_dim   = {0.500, 0.500, 0.560},
        accent_glow  = {1.000, 1.000, 1.000},
        text_primary   = {0.920, 0.920, 0.940},
        text_secondary = {0.520, 0.520, 0.560},
        text_accent    = {0.800, 0.800, 0.860},
        text_disabled  = {0.300, 0.300, 0.340},
        col_enabled  = {0.700, 0.700, 0.760},
        col_disabled = {0.280, 0.280, 0.320},
        col_ringing  = {1.000, 0.350, 0.100},
        col_snooze   = {0.400, 0.700, 1.000},
    },
}

Config.ACTIVE_THEME = 1

function Config.T()
    return Config.THEMES[Config.ACTIVE_THEME]
end

-- ============================================================
-- FONTS / PATHS
-- ============================================================
Config.FONT_PATH      = "Assets/Font/Font.ttf"
Config.FONT_BOLD_PATH = "Assets/Font/Font-Bold.ttf"
Config.ALARMS_PATH    = "data/alarms.txt"
Config.SETTINGS_PATH  = "data/settings.txt"
Config.SOUND_PATH     = "Assets/Sound/alarm.ogg"

-- ============================================================
-- ALARM SETTINGS
-- ============================================================
Config.MAX_ALARMS     = 5
Config.SNOOZE_OPTIONS = {5, 10, 15}
Config.DEFAULT_SNOOZE = 1
Config.DAY_LABELS     = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
Config.DAY_FULL       = {"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"}

-- ============================================================
-- LABEL PRESETS  (last entry opens keyboard)
-- ============================================================
Config.PRESET_LABELS = {
    "Wake Up", "Morning", "School", "Work", "Lunch",
    "Prayer", "Nap", "Evening", "Dinner", "Bedtime",
    "Medicine", "Meeting", "Gym", "Custom...",
}

-- ============================================================
-- ON-SCREEN KEYBOARD ROWS
-- ============================================================
Config.KB_ROWS = {
    {"1","2","3","4","5","6","7","8","9","0"},
    {"q","w","e","r","t","y","u","i","o","p"},
    {"a","s","d","f","g","h","j","k","l","-"},
    {"z","x","c","v","b","n","m","!","?","_"},
    {"SPACE","BACK","DONE"},
}

-- ============================================================
-- PERSIST SETTINGS
-- ============================================================
function Config.SaveSettings()
	love.filesystem.createDirectory("data")   -- ensure directory exists
    love.filesystem.write(Config.SETTINGS_PATH, tostring(Config.ACTIVE_THEME))
end

function Config.LoadSettings()
    if love.filesystem.getInfo(Config.SETTINGS_PATH) then
        local s = love.filesystem.read(Config.SETTINGS_PATH)
        if s then
            local n = tonumber(s:match("%d+"))
            if n and n >= 1 and n <= #Config.THEMES then
                Config.ACTIVE_THEME = n
            end
        end
    end
end

return Config
