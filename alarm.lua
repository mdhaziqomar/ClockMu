local Config = require("config")

local Alarm = {}

-- ============================================================
-- Alarm object factory
-- ============================================================
-- repeat_days: 7-bit integer, bit 1=Mon … bit 7=Sun.  0 = one-shot.
function Alarm.New(hour, minute, label, repeat_days, enabled)
    return {
        hour        = hour        or 7,
        minute      = minute      or 0,
        label       = label       or "Alarm",
        repeat_days = repeat_days or 0,       -- 0 = once
        enabled     = (enabled == nil) and true or enabled,
        snooze_idx  = Config.DEFAULT_SNOOZE,
        state       = "idle",  -- idle | ringing | snoozed
        snooze_until = nil,    -- os.time() target when snoozed
    }
end

-- ============================================================
-- Serialise / deserialise  (one alarm per line, pipe-separated)
-- Format: hour|minute|label|repeat_days|enabled|snooze_idx
-- ============================================================
function Alarm.Serialize(alarm)
    return string.format("%d|%d|%s|%d|%s|%d",
        alarm.hour,
        alarm.minute,
        alarm.label:gsub("|",""),   -- strip pipes from labels
        alarm.repeat_days,
        alarm.enabled and "1" or "0",
        alarm.snooze_idx)
end

function Alarm.Deserialize(line)
    local h,m,lbl,rep,en,sn = line:match("^(%d+)|(%d+)|([^|]*)|(%d+)|([01])|(%d+)$")
    if not h then return nil end
    return Alarm.New(
        tonumber(h), tonumber(m), lbl,
        tonumber(rep), en == "1"
    )
end

-- ============================================================
-- Save / Load all alarms to data/alarms.txt
-- ============================================================
function Alarm.SaveAll(alarms)
    love.filesystem.createDirectory("data")   -- ensure directory exists
    local lines = {}
    for _, a in ipairs(alarms) do
        table.insert(lines, Alarm.Serialize(a))
    end
    local ok, err = love.filesystem.write(Config.ALARMS_PATH, table.concat(lines, "\n") .. "\n")
    if not ok then
        print("Failed to save alarms:", err)
    end
    return ok, err
end

function Alarm.LoadAll()
    local alarms = {}
    if not love.filesystem.getInfo(Config.ALARMS_PATH) then
        return alarms
    end
    local contents, _ = love.filesystem.read(Config.ALARMS_PATH)
    if not contents then return alarms end
    for line in contents:gmatch("[^\n]+") do
        local a = Alarm.Deserialize(line)
        if a and #alarms < Config.MAX_ALARMS then
            table.insert(alarms, a)
        end
    end
    return alarms
end

-- ============================================================
-- Time helpers
-- ============================================================
function Alarm.TimeString(alarm)
    return string.format("%02d:%02d", alarm.hour, alarm.minute)
end

function Alarm.RepeatString(alarm)
    if alarm.repeat_days == 0 then return "Once" end
    if alarm.repeat_days == 127 then return "Every day" end
    -- Weekdays = Mon-Fri = bits 1-5 = 0b0011111 = 31
    if alarm.repeat_days == 31 then return "Weekdays" end
    -- Weekend = Sat+Sun = bits 6-7 = 0b1100000 = 96
    if alarm.repeat_days == 96 then return "Weekends" end
    local days = {}
    for i = 1, 7 do
        if bit.band(alarm.repeat_days, bit.lshift(1, i-1)) ~= 0 then
            table.insert(days, Config.DAY_LABELS[i])
        end
    end
    return table.concat(days, " ")
end

-- ============================================================
-- Check if an alarm should fire right now
-- ============================================================
function Alarm.ShouldFire(alarm)
    if not alarm.enabled then return false end
    if alarm.state == "ringing" then return false end

    local now = os.date("*t")

    -- Snoozed: check if snooze_until has passed
    if alarm.state == "snoozed" and alarm.snooze_until then
        if os.time() >= alarm.snooze_until then
            alarm.state = "idle"  -- fall through to normal check below
        else
            return false
        end
    end

    if alarm.state ~= "idle" then return false end

    local matchTime = (now.hour == alarm.hour and now.min == alarm.minute and now.sec == 0)
    if not matchTime then return false end

    if alarm.repeat_days == 0 then
        return true  -- one-shot, fires any day
    end

    -- Check day-of-week. Lua: 1=Sun, 2=Mon … 7=Sat
    -- Our bits: bit1=Mon … bit7=Sun
    local luaDow = now.wday  -- 1=Sun
    local ourBit = luaDow - 1  -- 0=Sun
    if ourBit == 0 then ourBit = 7 end  -- remap Sun to 7
    return bit.band(alarm.repeat_days, bit.lshift(1, ourBit - 1)) ~= 0
end

return Alarm
