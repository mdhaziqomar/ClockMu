local love = require("love")
local Config = require("config")
local Alarm  = require("alarm")

-- ============================================================
-- LAYOUT CONSTANTS  (all at 640x480 logical resolution)
-- ============================================================
local SW, SH       = 640, 480
local HDR_H        = 44          -- header bar height
local BTN_BAR_H    = 40          -- bottom button bar
local BTN_BAR_Y    = SH - BTN_BAR_H
local CONTENT_Y    = HDR_H + 4   -- first pixel below header
local CONTENT_H    = BTN_BAR_Y - CONTENT_Y  -- usable body height

local CLOCK_H      = 88          -- big clock block height
local CLOCK_Y      = CONTENT_Y + 2

local LIST_X       = 12
local LIST_W       = SW - LIST_X * 2
local LIST_Y       = CLOCK_Y + CLOCK_H + 6
local ALARM_ROW_H  = 44
local LIST_H       = BTN_BAR_Y - LIST_Y - 4  -- available for rows

-- ============================================================
-- STATE
-- ============================================================
local alarms    = {}
local selIdx    = 1

-- Scenes: "main" | "edit" | "preset_time" | "label_pick" | "keyboard"
--         | "theme" | "ringing" | "quit"
local scene     = "main"

-- Edit state
local editAlarm    = nil
local editField    = 1   -- 1=hour 2=min 3=label 4=repeat 5=snooze 6=enabled
local editRepDay   = 1

-- Preset time picker
local presetList   = {}
local presetIdx    = 1
local PRESET_PAGE  = 8

-- Label picker
local labelSelIdx  = 1

-- Keyboard state
local kbText       = ""
local kbRow        = 1
local kbCol        = 1
local kbMaxLen     = 20
local kbCapsLock   = false 

-- Theme picker
local themeSelIdx  = 1

-- Ringing
local ringingIdx   = nil
local ringTimer    = 0
local ringFlash    = false

-- Sound
local alarmSound   = nil

-- Tick guard
local lastFiredMin = -1

-- Fonts (loaded in love.load)
local fClock, fBig, fMed, fSm, fBoldBig, fBoldMed, fBoldSm, fBoldXs

-- Icons
local ic = {}   -- ic.A, ic.B, ic.X, ic.Y, ic.L1, ic.R1

-- ============================================================
-- COLOUR HELPERS
-- ============================================================
local function C(key, a)
    local t = Config.T()[key]
    love.graphics.setColor(t[1], t[2], t[3], a or 1)
end

local function CR(col, a)
    love.graphics.setColor(col[1], col[2], col[3], a or 1)
end

-- ============================================================
-- SAVE EDIT ALARM
-- ============================================================
local function saveEditAlarm()
    if editAlarm._isNew then
        if #alarms < Config.MAX_ALARMS then
            editAlarm._isNew = nil
            table.insert(alarms, editAlarm)
            selIdx = #alarms
        end
    else
        local idx = editAlarm._idx
        editAlarm._idx   = nil
        editAlarm._isNew = nil
        alarms[idx] = editAlarm
    end
    Alarm.SaveAll(alarms)
    scene = "main"
end

-- ============================================================
-- DRAW HELPERS
-- ============================================================
local function rect(mode, x, y, w, h, r)
    love.graphics.rectangle(mode, x, y, w, h, r or 0, r or 0)
end

-- Draw icon + label, advance x, return new x
local function btnHint(icon, label, x, y, font)
    love.graphics.setFont(font)
    C("text_primary")
    love.graphics.draw(icon, x, y + (BTN_BAR_H - 20) / 2)
    C("text_secondary")
    love.graphics.print(label, x + 26, y + (BTN_BAR_H - font:getHeight()) / 2)
    return x + 22 + font:getWidth(label) + 10
end

-- Draw right-aligned icon+label pair, return left edge used
local function btnHintRight(icon, label, rightEdge, y, font)
    love.graphics.setFont(font)
    local lw = font:getWidth(label)
    local totalW = 22 + lw
    local x = rightEdge - totalW - 8
    C("text_primary")
    love.graphics.draw(icon, x, y + (BTN_BAR_H - 20) / 2)
    C("text_secondary")
    love.graphics.print(label, x + 26, y + (BTN_BAR_H - font:getHeight()) / 2)
    return x
end

-- ============================================================
-- BUILD PRESET TIME LIST
-- ============================================================
local function buildPresets()
    presetList = {}
    for h = 0, 23 do
        for _, m in ipairs({0, 15, 30, 45}) do
            table.insert(presetList, {hour=h, minute=m})
        end
    end
end

-- ============================================================
-- SOUND
-- ============================================================
local function tryLoadSound()
    if love.filesystem.getInfo(Config.SOUND_PATH) then
        local ok, src = pcall(love.audio.newSource, Config.SOUND_PATH, "static")
        if ok then alarmSound = src; alarmSound:setLooping(true) end
    end
end

local function startRinging()
    if alarmSound then alarmSound:stop(); alarmSound:play() end
    ringTimer = 0; ringFlash = false
end

local function stopRinging()
    if alarmSound then alarmSound:stop() end
end

-- ============================================================
-- MAIN SCREEN COMPONENTS
-- ============================================================
local function drawHeader()
    C("bg_header")
    rect("fill", 0, 0, SW, HDR_H)
    C("accent_dim", 0.5)
    love.graphics.line(0, HDR_H, SW, HDR_H)

    -- App name
    love.graphics.setFont(fBoldBig)
    C("text_accent")
    love.graphics.print("ClockMu", 12, (HDR_H - fBoldBig:getHeight()) / 2)

    -- Current time (small, right side)
    local now = os.date("*t")
    local ts  = string.format("%02d:%02d", now.hour, now.min)
    love.graphics.setFont(fBoldMed)
    C("text_secondary")
    local tw = fBoldMed:getWidth(ts)
    love.graphics.print(ts, SW - tw - 10, (HDR_H - fBoldMed:getHeight()) / 2)

    -- Theme name (centre)
    love.graphics.setFont(fBoldXs)
    C("text_disabled")
    local tn = Config.THEMES[Config.ACTIVE_THEME].name
    local tnw = fBoldXs:getWidth(tn)
    love.graphics.print(tn, SW/2 - tnw/2, (HDR_H - fBoldXs:getHeight()) / 2)
end

local function drawClock()
    local now   = os.date("*t")
    local timeS = string.format("%02d:%02d", now.hour, now.min)
    local dateS = os.date("%A, %d %b %Y")

    -- Panel
    C("bg_panel")
    rect("fill", LIST_X, CLOCK_Y, LIST_W, CLOCK_H, 8)
    C("accent_dim", 0.3)
    rect("line", LIST_X, CLOCK_Y, LIST_W, CLOCK_H, 8)

    -- Time
    love.graphics.setFont(fClock)
    C("accent_glow")
    local tw = fClock:getWidth(timeS)
    love.graphics.print(timeS, SW/2 - tw/2, CLOCK_Y + 6)

    -- Date
    love.graphics.setFont(fBoldSm)
    C("text_secondary")
    local dw = fBoldSm:getWidth(dateS)
    love.graphics.print(dateS, SW/2 - dw/2, CLOCK_Y + CLOCK_H - fBoldSm:getHeight() - 8)
end

local function drawAlarmList()
    -- Section label
    love.graphics.setFont(fBoldXs)
    C("text_secondary")
    love.graphics.print("ALARMS  (" .. #alarms .. "/" .. Config.MAX_ALARMS .. ")", LIST_X, LIST_Y - 14)

    if #alarms == 0 then
        love.graphics.setFont(fMed)
        C("text_disabled")
        local msg = "No alarms.  Press Y to add one."
        local mw = fMed:getWidth(msg)
        love.graphics.print(msg, SW/2 - mw/2, LIST_Y + 30)
        return
    end

    for i, a in ipairs(alarms) do
        local ry = LIST_Y + (i - 1) * ALARM_ROW_H
        if ry + ALARM_ROW_H > BTN_BAR_Y - 4 then break end  -- don't overflow

        local isSel     = (i == selIdx)
        local isRinging = (scene == "ringing" and ringingIdx == i)

        -- Row bg
        if isRinging then
            C(ringFlash and "col_ringing" or "bg_row", ringFlash and 0.7 or 1)
        elseif isSel then
            C("bg_row_sel", 0.25)
        else
            C("bg_row", 0.8)
        end
        rect("fill", LIST_X, ry, LIST_W, ALARM_ROW_H - 2, 5)

        -- Selection border
        if isSel and scene == "main" then
            C("accent", 0.85)
            rect("line", LIST_X, ry, LIST_W, ALARM_ROW_H - 2, 5)
        end

        -- Time (left)
        love.graphics.setFont(fBoldBig)
        C(a.enabled and (isRinging and "col_ringing" or "accent_glow") or "text_disabled")
        love.graphics.print(Alarm.TimeString(a), LIST_X + 8, ry + 6)

        -- Label (top-right area)
        love.graphics.setFont(fBoldMed)
        C("text_primary")
        love.graphics.print(a.label, LIST_X + 108, ry + 5)

        -- Repeat string (below label)
        love.graphics.setFont(fBoldXs)
        C("text_secondary")
        love.graphics.print(Alarm.RepeatString(a), LIST_X + 108, ry + 24)

        -- Snooze (far right, small)
        local snoozeStr = Config.SNOOZE_OPTIONS[a.snooze_idx] .. "m"
        local snW = fBoldXs:getWidth(snoozeStr)
        love.graphics.print(snoozeStr, LIST_X + LIST_W - snW - 26, ry + 24)

        -- Enabled dot (far right)
        if a.enabled then C("col_enabled") else C("col_disabled") end
        love.graphics.circle("fill", LIST_X + LIST_W - 12, ry + 12, 6)

        -- Snoozed badge
        if a.state == "snoozed" then
            love.graphics.setFont(fBoldXs)
            C("col_snooze")
            love.graphics.print("ZZZ", LIST_X + LIST_W - 50, ry + 5)
        end
    end
end

local function drawBottomBar(hints)
    -- Bar background
    C("bg_btn_bar")
    rect("fill", 0, BTN_BAR_Y, SW, BTN_BAR_H)
    C("accent_dim", 0.3)
    love.graphics.line(0, BTN_BAR_Y, SW, BTN_BAR_Y)

    -- Left hints
    local x = 8
    for _, h in ipairs(hints.left or {}) do
        x = btnHint(h[1], h[2], x, BTN_BAR_Y, fBoldXs)
    end

    -- Right hints (B Quit always right-aligned with safe margin)
    local rx = SW - 8
    for i = #(hints.right or {}), 1, -1 do
        local h = hints.right[i]
        love.graphics.setFont(fBoldXs)
        local lw = fBoldXs:getWidth(h[2])
        rx = rx - lw - 22 - 4
        C("text_primary")
        love.graphics.draw(h[1], rx, BTN_BAR_Y + (BTN_BAR_H - 20) / 2)
        C("text_secondary")
        love.graphics.print(h[2], rx + 26, BTN_BAR_Y + (BTN_BAR_H - fBoldXs:getHeight()) / 2)
    end
end

-- ============================================================
-- MODAL SHELL  (draws dimmed backdrop + rounded panel)
-- ============================================================
local function modalShell(x, y, w, h, title)
    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.72)
    rect("fill", 0, 0, SW, SH)

    -- Panel body
    C("bg_modal")
    rect("fill", x, y, w, h, 8)

    -- Header strip
    C("bg_modal_hdr")
    rect("fill", x, y, w, 34, 8)
    rect("fill", x, y + 20, w, 14)  -- square bottom of header

    -- Title
    love.graphics.setFont(fBoldMed)
    C("text_accent")
    love.graphics.print(title, x + 12, y + 7)

    -- Separator line
    C("accent_dim", 0.3)
    love.graphics.line(x, y + 34, x + w, y + 34)
end

-- ============================================================
-- EDIT MODAL
-- ============================================================
local EDIT_FIELDS = {"Hour", "Minute", "Label", "Repeat Days", "Snooze", "Enabled"}

local function drawEditModal()
    local mx, my = 50, 40
    local mw, mh = SW - 100, SH - 80

    modalShell(mx, my, mw, mh, "Edit Alarm")

    -- Preview time top-right of header
    love.graphics.setFont(fBoldBig)
    C("accent_glow")
    local pt = string.format("%02d:%02d", editAlarm.hour, editAlarm.minute)
    local ptw = fBoldBig:getWidth(pt)
    love.graphics.print(pt, mx + mw - ptw - 10, my + 4)

    local fy   = my + 38
    local rowH = 42
    local valX = mx + 130

    for fi, fname in ipairs(EDIT_FIELDS) do
        local isAct = (fi == editField)
        local fbot  = fy + rowH

        if isAct then
            C("bg_row_sel", 0.2)
            rect("fill", mx + 4, fy, mw - 8, rowH - 2, 4)
            C("accent", 0.7)
            rect("line", mx + 4, fy, mw - 8, rowH - 2, 4)
        end

        -- Field label
        love.graphics.setFont(fBoldXs)
        C(isAct and "text_accent" or "text_secondary")
        love.graphics.print(fname, mx + 10, fy + 4)

        -- Value
        if fi == 1 then  -- Hour
            love.graphics.setFont(fBoldBig)
            C("text_primary")
            love.graphics.print(string.format("%02d", editAlarm.hour), valX, fy + 8)
            if isAct then
                love.graphics.setFont(fBoldXs)
                C("text_secondary")
                love.graphics.print("< > adjust   L1/R1 +/-1h", valX + 60, fy + 14)
            end

        elseif fi == 2 then  -- Minute
            love.graphics.setFont(fBoldBig)
            C("text_primary")
            love.graphics.print(string.format("%02d", editAlarm.minute), valX, fy + 8)
            if isAct then
                love.graphics.setFont(fBoldXs)
                C("text_secondary")
                love.graphics.print("< > +/-1m   L1/R1 +/-10m", valX + 60, fy + 14)
            end

        elseif fi == 3 then  -- Label
            love.graphics.setFont(fBoldMed)
            C("text_primary")
            love.graphics.print(editAlarm.label, valX, fy + 10)
            if isAct then
                love.graphics.setFont(fBoldXs)
                C("text_secondary")
                love.graphics.print("A = pick label", valX + fBoldMed:getWidth(editAlarm.label) + 8, fy + 14)
            end

        elseif fi == 4 then  -- Repeat days
            love.graphics.setFont(fBoldXs)
            local dx = valX
            for di, dlbl in ipairs(Config.DAY_LABELS) do
                local on     = bit.band(editAlarm.repeat_days, bit.lshift(1, di-1)) ~= 0
                local isCur  = isAct and (di == editRepDay)
                local bw, bh = 30, 20

                if isCur then
                    C("accent")
                    rect("fill", dx - 1, fy + 8, bw, bh, 3)
                    C("bg_main")
                elseif on then
                    C("accent_dim", 0.55)
                    rect("fill", dx - 1, fy + 8, bw, bh, 3)
                    C("accent_glow")
                else
                    C("text_disabled")
                end
                love.graphics.print(dlbl, dx + 2, fy + 10)
                dx = dx + bw + 3
            end
            -- "Once" badge
            C(editAlarm.repeat_days == 0 and "accent_glow" or "text_disabled")
            love.graphics.print(editAlarm.repeat_days == 0 and "[Once]" or "Once", dx + 2, fy + 10)

        elseif fi == 5 then  -- Snooze
            love.graphics.setFont(fBoldMed)
            C("text_primary")
            love.graphics.print(Config.SNOOZE_OPTIONS[editAlarm.snooze_idx] .. " min", valX, fy + 10)
            if isAct then
                love.graphics.setFont(fBoldXs)
                C("text_secondary")
                love.graphics.print("< > to change", valX + 80, fy + 14)
            end

        elseif fi == 6 then  -- Enabled
            love.graphics.setFont(fBoldMed)
            C(editAlarm.enabled and "col_enabled" or "col_disabled")
            love.graphics.print(editAlarm.enabled and "ON" or "OFF", valX, fy + 10)
        end

        fy = fy + rowH
    end

    -- Bottom button bar inside modal
    local bbY = my + mh - 34
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 34, 8)
    rect("fill", mx, bbY - 8, mw, 16)

    love.graphics.setFont(fBoldXs)
    local bx = mx + 8
    local function mhint(icon, label)
        C("text_primary"); love.graphics.draw(icon, bx, bbY + 7)
        C("text_secondary"); love.graphics.print(label, bx + 26, bbY + 9)
        bx = bx + 22 + fBoldXs:getWidth(label) + 12
    end
    -- A behaviour depends on field
    if editField == 4 then
        mhint(ic.A, "Toggle day")
        mhint(ic.X, "Clear all")
    elseif editField == 3 then
        mhint(ic.A, "Pick label")
    else
        mhint(ic.A, "Save")
    end
    mhint(ic.Y, "Preset time")
    -- B right-aligned
    local blabel = "Cancel"
    local bw2 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw2 - 26 - 10, bbY + 7)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw2 - 8, bbY + 9)
end

-- ============================================================
-- PRESET TIME PICKER
-- ============================================================
local function drawPresetTime()
    local mx, my = 120, 60
    local mw, mh = 400, 330

    modalShell(mx, my, mw, mh, "Pick a Time")

    local totalPages = math.ceil(#presetList / PRESET_PAGE)
    local currPage   = math.ceil(presetIdx / PRESET_PAGE)
    local idxStart   = (currPage - 1) * PRESET_PAGE + 1
    local idxEnd     = math.min(idxStart + PRESET_PAGE - 1, #presetList)

    -- Page indicator in header
    love.graphics.setFont(fBoldXs)
    C("text_secondary")
    local pgStr = currPage .. "/" .. totalPages
    love.graphics.print(pgStr, mx + mw - fBoldXs:getWidth(pgStr) - 10, my + 10)

    local rowH = 28
    local ry   = my + 38

    for idx = idxStart, idxEnd do
        local p   = presetList[idx]
        local isSel = (idx == presetIdx)

        if isSel then
            C("bg_row_sel", 0.3)
            rect("fill", mx + 4, ry, mw - 8, rowH - 2, 4)
            C("accent", 0.8)
            rect("line", mx + 4, ry, mw - 8, rowH - 2, 4)
        end

        love.graphics.setFont(isSel and fBoldBig or fBoldMed)
        C(isSel and "accent_glow" or "text_primary")
        love.graphics.print(string.format("%02d:%02d", p.hour, p.minute), mx + 14, ry + 3)
        ry = ry + rowH
    end

    -- Nav hints
    local bbY = my + mh - 32
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 32, 8)
    rect("fill", mx, bbY - 8, mw, 16)

    love.graphics.setFont(fBoldXs)
    local bx2 = mx + 8
    local function mhint2(icon, label)
        C("text_primary"); love.graphics.draw(icon, bx2, bbY + 6)
        C("text_secondary"); love.graphics.print(label, bx2 + 26
		, bbY + 8)
        bx2 = bx2 + 22 + fBoldXs:getWidth(label) + 12
    end
    mhint2(ic.A, "Select")
    mhint2(ic.L1, "Prev page")
    mhint2(ic.R1, "Next page")
    local blabel = "Cancel"
    local bw3 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw3 - 22 - 10, bbY + 6)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw3 - 8, bbY + 8)
end

-- ============================================================
-- LABEL PICKER
-- ============================================================
local function drawLabelPicker()
    local mx, my = 80, 50
    local mw, mh = SW - 160, SH - 100

    modalShell(mx, my, mw, mh, "Choose Label")

    local cols   = 2
    local itemH  = 30
    local colW   = (mw - 16) / cols
    local startY = my + 40
    local px     = mx + 8

    for idx, lbl in ipairs(Config.PRESET_LABELS) do
        local col = (idx - 1) % cols
        local row = math.floor((idx - 1) / cols)
        local rx2 = px + col * colW
        local ry2 = startY + row * itemH
        local isSel = (idx == labelSelIdx)

        if isSel then
            C("bg_row_sel", 0.3)
            rect("fill", rx2 - 2, ry2, colW - 4, itemH - 2, 4)
            C("accent", 0.8)
            rect("line", rx2 - 2, ry2, colW - 4, itemH - 2, 4)
        end

        love.graphics.setFont(isSel and fBoldMed or fMed)
        C(isSel and "accent_glow" or "text_primary")
        -- "Custom..." gets a special colour
        if lbl == "Custom..." then C(isSel and "accent_glow" or "text_accent") end
        love.graphics.print(lbl, rx2 + 4, ry2 + 6)
    end

    -- Bottom hints
    local bbY = my + mh - 32
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 32, 8)
    rect("fill", mx, bbY - 8, mw, 16)

    love.graphics.setFont(fBoldXs)
    local bx2 = mx + 8
    local function mhint(icon, label)
        C("text_primary"); love.graphics.draw(icon, bx2, bbY + 6)
        C("text_secondary"); love.graphics.print(label, bx2 + 26, bbY + 8)
        bx2 = bx2 + 22 + fBoldXs:getWidth(label) + 12
    end
    mhint(ic.A, "Select")
    local blabel = "Cancel"
    local bw4 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw4 - 26 - 10, bbY + 6)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw4 - 8, bbY + 8)
end

-- ============================================================
-- ON-SCREEN KEYBOARD
-- ============================================================
local function drawKeyboard()
    local mx, my = 20, 60
    local mw, mh = SW - 40, SH - 80

    modalShell(mx, my, mw, mh, "Enter Label")

    -- Text display
    local dispY  = my + 40
    local textStr = kbText .. "|"
    love.graphics.setFont(fBoldBig)
    C("accent_glow")
    love.graphics.print(textStr, mx + 10, dispY)

    love.graphics.setFont(fBoldXs)
    C("text_secondary")
    love.graphics.print(#kbText .. "/" .. kbMaxLen, mx + mw - 50, dispY + 6)

    -- Separator
    C("accent_dim", 0.3)
    love.graphics.line(mx + 4, dispY + 32, mx + mw - 4, dispY + 32)

    -- Keys
    local kbStartY = dispY + 38
    local rows     = Config.KB_ROWS

    for ri, row in ipairs(rows) do
        local isLastRow = (ri == #rows)
        local keyH = 28
        local keyW
        local totalKeys  = #row
        local totalWidth = mw - 16

        if isLastRow then
            -- Special wide keys row
            local widths = {SPACE=120, BACK=80, DONE=80}
            local usedW  = 0
            for _, k in ipairs(row) do usedW = usedW + (widths[k] or 60) + 4 end
            local startX = mx + 8 + (totalWidth - usedW) / 2

            for ci, k in ipairs(row) do
                local kw = widths[k] or 60
                local kx = startX
                for pi = 1, ci - 1 do
                    startX = startX + (widths[row[pi]] or 60) + 4
                end
                kx = startX
                startX = startX + kw + 4

                local isSel = (ri == kbRow and ci == kbCol)
                if isSel then C("accent") else C("bg_row", 0.8) end
                rect("fill", kx, kbStartY + (ri-1)*(keyH+4), kw, keyH, 4)
                if isSel then
                    C("bg_main")
                else
                    C("text_primary")
                end
                love.graphics.setFont(fBoldXs)
                local kLabel = k == "SPACE" and "Space" or k == "BACK" and "Del" or "Done"
                local klw = fBoldXs:getWidth(kLabel)
                love.graphics.print(kLabel, kx + kw/2 - klw/2, kbStartY + (ri-1)*(keyH+4) + 8)
            end
        else
            keyW = math.floor((totalWidth - (totalKeys-1)*4) / totalKeys)
            for ci, k in ipairs(row) do
                local kx  = mx + 8 + (ci-1)*(keyW+4)
                local ky  = kbStartY + (ri-1)*(keyH+4)
                local isSel = (ri == kbRow and ci == kbCol)

                if isSel then C("accent") else C("bg_row", 0.8) end
                rect("fill", kx, ky, keyW, keyH, 3)
                if isSel then C("bg_main") else C("text_primary") end
                love.graphics.setFont(fBoldSm)
                -- ★★★ FIX: Show uppercase if Caps Lock is ON ★★★
                local displayKey = kbCapsLock and k:upper() or k
                local klw = fBoldSm:getWidth(displayKey)
                love.graphics.print(displayKey, kx + keyW/2 - klw/2, ky + 6)
            end
        end
    end

    -- Bottom hints
    local bbY = my + mh - 30
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 30, 8)
    rect("fill", mx, bbY - 6, mw, 14)
    love.graphics.setFont(fBoldXs)
    local bx2 = mx + 8
    local function kh(icon, label)
        C("text_primary"); love.graphics.draw(icon, bx2, bbY + 5)
        C("text_secondary"); love.graphics.print(label, bx2 + 26, bbY + 7)
        bx2 = bx2 + 22 + fBoldXs:getWidth(label) + 10
    end
    kh(ic.A, "Type key")
    kh(ic.X, "Backspace")
    
    -- ★★★ Optional: Show Caps Lock state on the Y hint ★★★
    local capsLabel = kbCapsLock and "Caps ON" or "Caps OFF"
    kh(ic.Y, capsLabel)
    
    local blabel = "Cancel"
    local bw5 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw5 - 26 - 8, bbY + 5)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw5 - 6, bbY + 7)
end

-- ============================================================
-- THEME PICKER
-- ============================================================
local function drawThemePicker()
    local mx, my = 60, 50
    local mw, mh = SW - 120, SH - 100

    modalShell(mx, my, mw, mh, "Choose Theme")

    local rowH   = 34
    local startY = my + 40

    for ti, theme in ipairs(Config.THEMES) do
        local ry2  = startY + (ti - 1) * rowH
        local isSel = (ti == themeSelIdx)
        local isCur = (ti == Config.ACTIVE_THEME)

        if isSel then
            C("bg_row_sel", 0.3)
            rect("fill", mx + 4, ry2, mw - 8, rowH - 2, 4)
            C("accent", 0.8)
            rect("line", mx + 4, ry2, mw - 8, rowH - 2, 4)
        end

        -- Colour swatch
        local sw = theme.accent
        love.graphics.setColor(sw[1], sw[2], sw[3], 1)
        rect("fill", mx + 10, ry2 + 7, 18, 18, 3)
        love.graphics.setColor(1,1,1,0.4)
        rect("line", mx + 10, ry2 + 7, 18, 18, 3)

        -- Name
        love.graphics.setFont(isSel and fBoldMed or fMed)
        C(isSel and "accent_glow" or "text_primary")
        love.graphics.print(theme.name, mx + 36, ry2 + 8)

        -- Active badge
        if isCur then
            love.graphics.setFont(fBoldXs)
            C("col_enabled")
            love.graphics.print("[active]", mx + mw - 70, ry2 + 10)
        end
    end

    -- Bottom hints
    local bbY = my + mh - 32
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 32, 8)
    rect("fill", mx, bbY - 8, mw, 16)

    love.graphics.setFont(fBoldXs)
    local bx2 = mx + 8
    local function th(icon, label)
        C("text_primary"); love.graphics.draw(icon, bx2, bbY + 6)
        C("text_secondary"); love.graphics.print(label, bx2 + 26, bbY + 8)
        bx2 = bx2 + 22 + fBoldXs:getWidth(label) + 12
    end
    th(ic.A, "Apply theme")
    local blabel = "Cancel"
    local bw6 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw6 - 26 - 10, bbY + 6)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw6 - 8, bbY + 8)
end

-- ============================================================
-- RINGING OVERLAY
-- ============================================================
local function drawRinging()
    local a = alarms[ringingIdx]
    if not a then return end

    love.graphics.setColor(0, 0, 0, ringFlash and 0.5 or 0.75)
    rect("fill", 0, 0, SW, SH)

    local mx, my = 80, 100
    local mw, mh = SW - 160, 250

    C("bg_modal")
    rect("fill", mx, my, mw, mh, 10)
    C("col_ringing", 0.9)
    rect("line", mx, my, mw, mh, 10)

    -- Header strip
    C("col_ringing", ringFlash and 0.8 or 0.5)
    rect("fill", mx, my, mw, 38, 10)
    rect("fill", mx, my + 24, mw, 14)

    love.graphics.setFont(fBoldMed)
    C("text_primary")
    love.graphics.print("!! ALARM !!", mx + mw/2 - fBoldMed:getWidth("!! ALARM !!")/2, my + 8)

    -- Time
    love.graphics.setFont(fClock)
    C("accent_glow")
    local ts = Alarm.TimeString(a)
    love.graphics.print(ts, mx + mw/2 - fClock:getWidth(ts)/2, my + 46)

    -- Label
    love.graphics.setFont(fBoldMed)
    C("text_primary")
    love.graphics.print(a.label, mx + mw/2 - fBoldMed:getWidth(a.label)/2, my + 130)

    -- Buttons
    local bbY = my + mh - 44
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 44, 10)
    rect("fill", mx, bbY - 10, mw, 20)

    love.graphics.setFont(fBoldSm)
    -- Snooze left
    C("col_snooze", 0.9); love.graphics.draw(ic.A, mx + 10, bbY + 12)
    C("text_primary")
    love.graphics.print("Snooze (" .. Config.SNOOZE_OPTIONS[a.snooze_idx] .. "m)", mx + 34, bbY + 14)

    -- Dismiss right
    local dlabel = "Dismiss"
    local dlw    = fBoldSm:getWidth(dlabel)
    C("col_ringing", 0.9); love.graphics.draw(ic.B, mx + mw - dlw - 30, bbY + 12)
    C("text_primary"); love.graphics.print(dlabel, mx + mw - dlw - 6, bbY + 14)
end

-- ============================================================
-- QUIT CONFIRM
-- ============================================================
local function drawQuitConfirm()
    love.graphics.setColor(0, 0, 0, 0.75)
    rect("fill", 0, 0, SW, SH)

    local mx, my = 160, 170
    local mw, mh = 320, 120

    modalShell(mx, my, mw, mh, "Quit ClockMu?")

    love.graphics.setFont(fBoldXs)
    C("text_secondary")
    love.graphics.print("Alarms stop when the app closes.", mx + 10, my + 46)

    local bbY = my + mh - 34
    C("bg_modal_hdr")
    rect("fill", mx, bbY, mw, 34, 8)
    rect("fill", mx, bbY - 8, mw, 16)

    love.graphics.setFont(fBoldXs)
    C("text_primary"); love.graphics.draw(ic.A, mx + 4, bbY + 7)
    C("text_secondary"); love.graphics.print("Yes, quit", mx + 30, bbY + 9)

    local blabel = "No, stay"
    local bw7 = fBoldXs:getWidth(blabel)
    C("text_primary"); love.graphics.draw(ic.B, mx + mw - bw7 - 26 - 10, bbY + 7)
    C("text_secondary"); love.graphics.print(blabel, mx + mw - bw7 - 8, bbY + 9)
end

-- ============================================================
-- LOVE CALLBACKS
-- ============================================================
function love.load()
    fClock    = love.graphics.newFont(Config.FONT_BOLD_PATH, 54)
    fBoldBig  = love.graphics.newFont(Config.FONT_BOLD_PATH, 20)
    fBoldMed  = love.graphics.newFont(Config.FONT_BOLD_PATH, 15)
    fBoldSm   = love.graphics.newFont(Config.FONT_BOLD_PATH, 13)
    fBoldXs   = love.graphics.newFont(Config.FONT_BOLD_PATH, 11)
    fBig      = love.graphics.newFont(Config.FONT_PATH, 18)
    fMed      = love.graphics.newFont(Config.FONT_PATH, 14)
    fSm       = love.graphics.newFont(Config.FONT_PATH, 11)

    ic.A  = love.graphics.newImage("Assets/Icon/Xbox A.png")
    ic.B  = love.graphics.newImage("Assets/Icon/Xbox B.png")
    ic.X  = love.graphics.newImage("Assets/Icon/Xbox X.png")
    ic.Y  = love.graphics.newImage("Assets/Icon/Xbox Y.png")
    ic.L1 = love.graphics.newImage("Assets/Icon/L1.png")
    ic.R1 = love.graphics.newImage("Assets/Icon/R1.png")
	ic.start = love.graphics.newImage("Assets/Icon/Start.png")

    buildPresets()
    Config.LoadSettings()
    alarms = Alarm.LoadAll()
    tryLoadSound()
	
	-- ★★★ ADD THIS LINE ★★★
    love.filesystem.createDirectory("data")
end

function love.update(dt)
    if scene == "ringing" then
        ringTimer = ringTimer + dt
        if ringTimer >= 0.5 then ringTimer = 0; ringFlash = not ringFlash end
        return
    end

    local now       = os.date("*t")
    local minuteKey = now.hour * 60 + now.min
    if minuteKey ~= lastFiredMin and now.sec == 0 then
        for i, a in ipairs(alarms) do
            if Alarm.ShouldFire(a) then
                lastFiredMin = minuteKey
                ringingIdx   = i
                scene        = "ringing"
                a.state      = "ringing"
                startRinging()
                Alarm.SaveAll(alarms)
                break
            end
        end
    end
end

function love.draw()
    local sx = love.graphics.getWidth()  / SW
    local sy = love.graphics.getHeight() / SH
    love.graphics.push()
    love.graphics.scale(sx, sy)

    C("bg_main")
    rect("fill", 0, 0, SW, SH)

    drawHeader()
    drawClock()
    drawAlarmList()

    -- Main screen bottom bar
    if scene == "main" then
        local T = Config.T()
        drawBottomBar({
            left  = {
                {ic.A,  "Edit"},
                {ic.X,  "Toggle"},
                {ic.Y,  "Add"},
                {ic.L1, "Delete"},
                {ic.R1, "Theme"},
            },
            right = {{ic.B, "Quit"}},
        })
    end

    -- Scene overlays
    if scene == "edit"        then drawEditModal()   end
    if scene == "preset_time" then drawPresetTime()  end
    if scene == "label_pick"  then drawLabelPicker() end
    if scene == "keyboard"    then drawKeyboard()    end
    if scene == "theme"       then drawThemePicker() end
    if scene == "ringing"     then drawRinging()     end
    if scene == "quit"        then drawQuitConfirm() end

    love.graphics.pop()
end

-- ============================================================
-- INPUT ROUTING
-- ============================================================
function love.keypressed(key)
    OnKeyPress(key)
end

function love.gamepadpressed(joystick, button)
    local map = {
        dpleft="left", dpright="right", dpup="up", dpdown="down",
        a="a", b="b", x="x", y="y",
        back="select", start="start",
        leftshoulder="l1", rightshoulder="r1",
    }
    local k = map[button]
    if k then OnKeyPress(k) end
end

function OnKeyPress(key)
    -- ---- Quit ----
    if scene == "quit" then
        if key == "a" then love.event.quit() end
        if key == "b" then scene = "main" end
        return
    end

    -- ---- Ringing ----
    if scene == "ringing" then
        local a = alarms[ringingIdx]
        if key == "b" then
            stopRinging()
            a.state = "idle"
            if a.repeat_days == 0 then a.enabled = false end
            scene = "main"
            Alarm.SaveAll(alarms)
        elseif key == "a" then
            stopRinging()
            a.state       = "snoozed"
            a.snooze_until = os.time() + Config.SNOOZE_OPTIONS[a.snooze_idx] * 60
            scene = "main"
            Alarm.SaveAll(alarms)
        end
        return
    end

    -- ---- Theme picker ----
    if scene == "theme" then
        local n = #Config.THEMES
        if key == "up"   then themeSelIdx = themeSelIdx > 1 and themeSelIdx - 1 or n end
        if key == "down" then themeSelIdx = themeSelIdx < n and themeSelIdx + 1 or 1 end
        if key == "a" then
            Config.ACTIVE_THEME = themeSelIdx
            Config.SaveSettings()
            scene = "main"
        end
        if key == "b" then scene = "main" end
        return
    end

    -- ---- Keyboard ----
    if scene == "keyboard" then
        local rows = Config.KB_ROWS
        if key == "up" then
            kbRow = kbRow > 1 and kbRow - 1 or #rows
            kbCol = math.min(kbCol, #rows[kbRow])
        elseif key == "down" then
            kbRow = kbRow < #rows and kbRow + 1 or 1
            kbCol = math.min(kbCol, #rows[kbRow])
        elseif key == "left" then
            kbCol = kbCol > 1 and kbCol - 1 or #rows[kbRow]
        elseif key == "right" then
            kbCol = kbCol < #rows[kbRow] and kbCol + 1 or 1
        elseif key == "a" then
            local ch = rows[kbRow][kbCol]
            if ch == "DONE" then
                if kbText ~= "" then editAlarm.label = kbText end
                scene = "edit"
            elseif ch == "BACK" then
                kbText = kbText:sub(1, -2)
            elseif ch == "SPACE" then
                if #kbText < kbMaxLen then kbText = kbText .. " " end
            else
                if #kbText < kbMaxLen then
                    local out = kbCapsLock and ch:upper() or ch
                    kbText = kbText .. out
                end
            end
        elseif key == "y" then
            kbCapsLock = not kbCapsLock
        elseif key == "b" then
            scene = "edit"   -- cancel keyboard, back to edit
		elseif key == "x" then
			kbText = kbText:sub(1, -2)
        end
        return
    end

    -- ---- Label picker ----
    if scene == "label_pick" then
        local n = #Config.PRESET_LABELS
        local cols = 2
        if key == "up"    then labelSelIdx = labelSelIdx > cols and labelSelIdx - cols or labelSelIdx end
        if key == "down"  then labelSelIdx = labelSelIdx + cols <= n and labelSelIdx + cols or labelSelIdx end
        if key == "left"  then labelSelIdx = labelSelIdx > 1 and labelSelIdx - 1 or 1 end
        if key == "right" then labelSelIdx = labelSelIdx < n and labelSelIdx + 1 or n end
        if key == "a" then
            local chosen = Config.PRESET_LABELS[labelSelIdx]
            if chosen == "Custom..." then
                kbText = editAlarm.label
                kbRow, kbCol = 1, 1
                scene = "keyboard"
            else
                editAlarm.label = chosen
                scene = "edit"
            end
        end
        if key == "b" then scene = "edit" end
        return
    end

    -- ---- Preset time picker ----
    if scene == "preset_time" then
        local total     = #presetList
        local currPage  = math.ceil(presetIdx / PRESET_PAGE)
        local totalPage = math.ceil(total / PRESET_PAGE)

        if key == "up"    then presetIdx = presetIdx > 1 and presetIdx - 1 or total end
        if key == "down"  then presetIdx = presetIdx < total and presetIdx + 1 or 1 end
        if key == "l1"    then
            local np = currPage > 1 and currPage - 1 or totalPage
            presetIdx = (np - 1) * PRESET_PAGE + 1
        end
        if key == "r1"    then
            local np = currPage < totalPage and currPage + 1 or 1
            presetIdx = (np - 1) * PRESET_PAGE + 1
        end
        if key == "a" then
            local p = presetList[presetIdx]
            editAlarm.hour   = p.hour
            editAlarm.minute = p.minute
            scene = "edit"
        end
        if key == "b" then scene = "edit" end
        return
    end

    -- ---- Edit modal ----
    if scene == "edit" then
        if key == "up" then
            editField = editField > 1 and editField - 1 or #EDIT_FIELDS
        elseif key == "down" then
            editField = editField < #EDIT_FIELDS and editField + 1 or 1

        elseif key == "right" then
            if editField == 1 then editAlarm.hour = (editAlarm.hour + 1) % 24
            elseif editField == 2 then editAlarm.minute = (editAlarm.minute + 1) % 60
            elseif editField == 4 then editRepDay = editRepDay < 7 and editRepDay + 1 or 1
            elseif editField == 5 then
                local n = #Config.SNOOZE_OPTIONS
                editAlarm.snooze_idx = editAlarm.snooze_idx < n and editAlarm.snooze_idx + 1 or 1
            elseif editField == 6 then editAlarm.enabled = not editAlarm.enabled
            end

        elseif key == "left" then
            if editField == 1 then editAlarm.hour = (editAlarm.hour - 1 + 24) % 24
            elseif editField == 2 then editAlarm.minute = (editAlarm.minute - 1 + 60) % 60
            elseif editField == 4 then editRepDay = editRepDay > 1 and editRepDay - 1 or 7
            elseif editField == 5 then
                local n = #Config.SNOOZE_OPTIONS
                editAlarm.snooze_idx = editAlarm.snooze_idx > 1 and editAlarm.snooze_idx - 1 or n
            elseif editField == 6 then editAlarm.enabled = not editAlarm.enabled
            end

        elseif key == "l1" then
            if editField == 1 then editAlarm.hour = (editAlarm.hour - 1 + 24) % 24
            elseif editField == 2 then editAlarm.minute = (editAlarm.minute - 10 + 60) % 60
            end
        elseif key == "r1" then
            if editField == 1 then editAlarm.hour = (editAlarm.hour + 1) % 24
            elseif editField == 2 then editAlarm.minute = (editAlarm.minute + 10) % 60
            end

        elseif key == "a" then
            if editField == 3 then
                -- Open label picker
                labelSelIdx = 1
                scene = "label_pick"
            elseif editField == 4 then
                local mask = bit.lshift(1, editRepDay - 1)
                editAlarm.repeat_days = bit.bxor(editAlarm.repeat_days, mask)
            else
                -- Save
                saveEditAlarm() 
            end
			elseif key == "start" then
				saveEditAlarm()   -- save from anywhere in the edit screen

        elseif key == "x" and editField == 4 then
            editAlarm.repeat_days = 0

        elseif key == "y" then
            -- Open preset time picker, pre-select closest time
            local target = editAlarm.hour * 60 + editAlarm.minute
            local best, bestDist = 1, math.huge
            for pi, p in ipairs(presetList) do
                local d = math.abs(p.hour * 60 + p.minute - target)
                if d < bestDist then bestDist = d; best = pi end
            end
            presetIdx = best
            scene = "preset_time"

        elseif key == "b" then
            scene = "main"
        end
        return
    end

    -- ---- Main screen ----
    if scene == "main" then
        if key == "up"   then selIdx = selIdx > 1 and selIdx - 1 or math.max(1, #alarms) end
        if key == "down" then selIdx = selIdx < #alarms and selIdx + 1 or 1 end

        if key == "a" and #alarms > 0 then
            local a = alarms[selIdx]
            editAlarm = {
                hour=a.hour, minute=a.minute, label=a.label,
                repeat_days=a.repeat_days, enabled=a.enabled,
                snooze_idx=a.snooze_idx, state=a.state,
                snooze_until=a.snooze_until,
                _idx=selIdx, _isNew=false
            }
            editField = 1; editRepDay = 1
            scene = "edit"
        end

        if key == "x" and #alarms > 0 then
            alarms[selIdx].enabled = not alarms[selIdx].enabled
            Alarm.SaveAll(alarms)
        end

        if key == "y" then
            if #alarms < Config.MAX_ALARMS then
                local now = os.date("*t")
                editAlarm = Alarm.New(now.hour, now.min, "Alarm " .. (#alarms + 1), 0, true)
                editAlarm._isNew = true
                editField = 1; editRepDay = 1
                scene = "edit"
            end
        end

        if key == "l1" and #alarms > 0 then
            table.remove(alarms, selIdx)
            if selIdx > #alarms and selIdx > 1 then selIdx = selIdx - 1 end
            Alarm.SaveAll(alarms)
        end

        if key == "r1" then
            themeSelIdx = Config.ACTIVE_THEME
            scene = "theme"
        end

        if key == "b" then scene = "quit" end
    end
	
	function love.quit()
		-- Save all alarms before quitting
		Alarm.SaveAll(alarms)
		-- Save current theme and other settings
		Config.SaveSettings()
		-- Return nothing (allow quit)
	end
	
end
