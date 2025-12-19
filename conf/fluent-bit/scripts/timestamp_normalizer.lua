-- Timestamp Normalizer for Fluent-Bit
-- Fixes parsing errors for timestamps without milliseconds
-- Example: 2025-12-19T03:00:16Z -> 2025-12-19T03:00:16.000Z

function normalize_timestamp(tag, timestamp, record)
    -- Check if 'time' field exists and needs normalization
    if record["time"] then
        local time_str = record["time"]
        -- Pattern: ISO 8601 without milliseconds (e.g., 2025-12-19T03:00:16Z)
        -- Match: YYYY-MM-DDTHH:MM:SSZ (no dot before Z)
        if string.match(time_str, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ$") then
            -- Add .000 milliseconds before Z
            record["time"] = string.gsub(time_str, "Z$", ".000Z")
        -- Pattern: ISO 8601 without milliseconds with timezone offset
        -- Match: YYYY-MM-DDTHH:MM:SS+HH:MM or YYYY-MM-DDTHH:MM:SS-HH:MM
        elseif string.match(time_str, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d[%+%-]%d%d:%d%d$") then
            -- Add .000 milliseconds before timezone offset
            record["time"] = string.gsub(time_str, "([%+%-]%d%d:%d%d)$", ".000%1")
        end
    end

    -- Return: 0 = keep record, 1 = modify timestamp, 2 = drop record
    return 1, timestamp, record
end
