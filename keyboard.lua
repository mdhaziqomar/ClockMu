-- ============================================================
-- ClockMu On-Screen Keyboard
-- D-pad navigation, A=type, B=backspace, X=space,
-- Y=switch case, L1=quick labels, R1=done/confirm
-- ============================================================

local Keyboard = {}

-- Layout rows: lowercase, uppercase, numbers/symbols
local ROWS = {
    lower = {
        {"a","b","c","d","e","f","g","h","i","j","k","l","m"},
        {"n","o","p","q","r","s","t","u","v","w","x","y","z"},
        {"1","2","3","4","5","6","7","8","9","0","-","_","."},
    },
    upper = {
        {"A","B","C","D","E","F","G","H","I","J","K","L","M"},
        {"N","O","P","Q","R","S","T","U","V","W","X","Y","Z"},
        {"1","2","3","4","5","6","7","8","9","0","-","_","."},
    },
}

local QUICK_LABELS = {
    "Alarm", "Morning", "Wake Up", "Work",
    "School", "Prayer", "Nap", "Gym",
    "Meds", "Meeting", "Custom",
}

-- State (reset on each open)
local text        = ""
local curRow      = 1
local curCol      = 1
local mode        = "lower"   -- "lower" | "upper"
local isQuick     = false
local quickIdx    = 1
local maxLen      = 20

local fontKb, fontKbSmall, fontKbTiny
local ic_A, ic_B, ic_X, ic_Y, ic_L1, ic_R1

local onDone   = nil   -- callback(text)
local onCancel = nil   -- callback()

-- ============================================================
-- Public API
-- ============================================================

function Keyboard.Load(fonts, icons)
    fontKb      = fonts.bold
    fontKbSmall = fonts.boldSmall
    fontKbTiny  = fonts.boldSmallest
    ic_A  = icons.A
    ic_B  = icons.B
    ic_X  = icons.X
    ic_Y  = icons.Y
    ic_L1 = icons.L1
    ic_R1 = icons.R1
end

function Keyboard.Open(initialText, cbDone, cbCancel)
    text      = initialText or ""
    curRow    = 1
    curCol    = 1
    mode      = "lower"
    isQuick   = false
    quickIdx  = 1
    onDone    = cbDone
    onCancel  = cbCancel
end

function Keyboard.KeyPress(key, T)
    if isQuick then
        if key == "up" then
            quickIdx = quickIdx > 1 and quickIdx - 1 or #QUICK_LABELS
        elseif key == "down" then
            quickIdx = quickIdx < #QUICK_LABELS and quickIdx + 1 or 1
        elseif key == "a" then
            text    = QUICK_LABELS[quickIdx]
            isQuick = false
        elseif key == "b" or key == "l1" then
            isQuick = false
        end
        return
    end

    local rows = ROWS[mode]
    local rowCount = #rows
    local colCount = #rows[curRow]

    if key == "up" then
        curRow = curRow > 1 and curRow - 1 or rowCount
        curCol = math.min(curCol, #rows[curRow])
    elseif key == "down" then
        curRow = curRow < rowCount and curRow + 1 or 1
        curCol = math.min(curCol, #rows[curRow])
    elseif key == "left" then
        curCol = curCol > 1 and curCol - 1 or #rows[curRow]
    elseif key == "right" then
        curCol = curCol < #rows[curRow] and curCol + 1 or 1
    elseif key == "a" then
        -- Type character
        if #text < maxLen then
            text = text .. rows[curRow][curCol]
        end
    elseif key == "b" then
        -- Backspace
        if #text > 0 then
            text = text:sub(1, #text - 1)
        else
            if onCancel then onCancel() end
        end
    elseif key == "x" then
        -- Space
        if #text < maxLen then
            text = text .. " "
        end
    elseif key == "y" then
        -- Toggle case
        mode = (mode == "lower") and "upper" or "lower"
    elseif key == "l1" then
        -- Quick labels
        isQuick = true
    elseif key == "r1" then
        -- Confirm
        local out = text
        if out == "" then out = "Alarm" end
        if onDone then onDone(out) end
    end
end

-- ============================================================
-- Draw
-- ============================================================
function Keyboard.Draw(T)
    local setCol = function(col, a)
        love.graphics.setColor(col[1], col[2], col[3], a or 1)
    end

    -- Background overlay
    setCol({0,0,0}, 0.82)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    local KX, KY = 20, 20
    local KW, KH = 600, 440

    setCol(T.bg_modal)
    love.graphics.rectangle("fill", KX, KY, KW, KH, 8, 8)

    -- Header
    setCol(T.bg_modal_hdr)
    love.graphics.rectangle("fill", KX, KY, KW, 34, 8, 8)
    love.graphics.rectangle("fill", KX, KY+20, KW, 14)

    love.graphics.setFont(fontKb)
    setCol(T.text_accent)
    love.graphics.print("Label", KX + 14, KY + 6)

    -- Mode indicator
    love.graphics.setFont(fontKbTiny)
    setCol(T.text_secondary)
    local modeStr = (mode == "upper") and "CAPS" or "abc"
    love.graphics.print(modeStr, KX + KW - 40, KY + 12)

    -- Text input display
    local TX, TY = KX + 10, KY + 42
    local TW, TH = KW - 20, 32
    setCol(T.bg_panel)
    love.graphics.rectangle("fill", TX, TY, TW, TH, 4, 4)
    setCol(T.accent, 0.6)
    love.graphics.rectangle("line", TX, TY, TW, TH, 4, 4)

    love.graphics.setFont(fontKb)
    setCol(T.text_primary)
    local displayText = text
    -- Truncate display if too long
    while fontKb:getWidth(displayText .. "_") > TW - 10 do
        displayText = displayText:sub(2)
    end
    love.graphics.print(displayText, TX + 6, TY + 6)

    -- Blinking cursor (use | char which is safe ASCII)
    setCol(T.accent_glow)
    love.graphics.print("|", TX + 6 + fontKb:getWidth(displayText), TY + 6)

    -- Quick label list
    if isQuick then
        local QX, QY = KX + 10, KY + 82
        local QW, QH = KW - 20, 290
        setCol(T.bg_modal_hdr)
        love.graphics.rectangle("fill", QX, QY, QW, QH, 6, 6)

        love.graphics.setFont(fontKb)
        setCol(T.text_accent)
        love.graphics.print("Quick Labels", QX + 10, QY + 6)

        local lineH = 26
        for i, lbl in ipairs(QUICK_LABELS) do
            local ly = QY + 32 + (i-1) * lineH
            if i == quickIdx then
                setCol(T.bg_row_sel, 0.4)
                love.graphics.rectangle("fill", QX + 4, ly, QW - 8, lineH - 2, 4, 4)
                setCol(T.accent)
                love.graphics.rectangle("line", QX + 4, ly, QW - 8, lineH - 2, 4, 4)
                setCol(T.accent_glow)
            else
                setCol(T.text_primary)
            end
            love.graphics.setFont(fontKbSmall)
            love.graphics.print(lbl, QX + 12, ly + 4)
        end

        -- Hints
        love.graphics.setFont(fontKbTiny)
        setCol(T.text_secondary)
        love.graphics.draw(ic_A, QX + 4, QY + QH - 22)
        love.graphics.print("Use", QX + 28, QY + QH - 18)
        love.graphics.draw(ic_B, QX + 70, QY + QH - 22)
        love.graphics.print("Back", QX + 94, QY + QH - 18)
        return
    end

    -- Keyboard grid
    local rows = ROWS[mode]
    local GY   = KY + 84
    local cellW = 44
    local cellH = 30
    local gapX  = 2
    local gapY  = 4

    for ri, row in ipairs(rows) do
        local rowW   = #row * (cellW + gapX) - gapX
        local startX = KX + (KW - rowW) / 2
        for ci, ch in ipairs(row) do
            local cx = startX + (ci-1) * (cellW + gapX)
            local cy = GY + (ri-1) * (cellH + gapY)
            local isSelected = (ri == curRow and ci == curCol)

            if isSelected then
                setCol(T.accent)
                love.graphics.rectangle("fill", cx, cy, cellW, cellH, 4, 4)
                setCol(T.bg_main)
            else
                setCol(T.bg_row, 0.8)
                love.graphics.rectangle("fill", cx, cy, cellW, cellH, 4, 4)
                setCol(T.text_primary)
            end

            love.graphics.setFont(fontKbSmall)
            local tw = fontKbSmall:getWidth(ch)
            love.graphics.print(ch, cx + cellW/2 - tw/2, cy + 7)
        end
    end

    -- Bottom hint bar
    local BHY = KY + KH - 38
    setCol(T.bg_modal_hdr)
    love.graphics.rectangle("fill", KX, BHY, KW, 38, 8, 8)
    love.graphics.rectangle("fill", KX, BHY, KW, 10)

    love.graphics.setFont(fontKbTiny)
    local bx = KX + 8

    local function bhint(icon, label)
        setCol(T.text_primary)
        love.graphics.draw(icon, bx, BHY + 10)
        setCol(T.text_secondary)
        love.graphics.print(label, bx + 22, BHY + 13)
        bx = bx + 22 + fontKbTiny:getWidth(label) + 10
    end

    bhint(ic_A,  "Type")
    bhint(ic_B,  "Del")
    bhint(ic_X,  "Space")
    bhint(ic_Y,  mode == "lower" and "CAPS" or "abc")
    bhint(ic_L1, "Quick")
    bhint(ic_R1, "Done")
end

return Keyboard
