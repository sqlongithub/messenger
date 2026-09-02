local _packets = {} -- Unprocessed scoresub packets
local _old = {}     -- Packets that have already been processed
local _table = ""   -- Scoresub table name
local _highest = 0  -- The highest ping in scoresub

-- Cache
local _icons = {}     -- Cached icons loaded by scoresub
local _usernames = {} -- Cached usernames

-- Manual rate-limiting to prevent crashing picotron
local _rate_limit = t()
local _rate_sent = 0

-- Utils ========================================

-- Returns an item if the table contains it.
local function has(tbl,v)
    return add(tbl, del(tbl,v))
end

-- Scoresub =====================================

-- Polls the current scoresub state
-- Skips packets already recieved by scoresub
-- include_sent <boolean> Include packets send by the user
function scoresub_poll(include_sent)
    local newstate = scoresub(_table) or {}
    local id = stat(64)

    -- Get the latest ping
    if newstate[1] then
        _highest = newstate[1].score
    end

    -- Generate all non-duplicate packets
    for i,entry in ipairs(newstate) do
        local data = split(entry.extra, ":", false)

        -- Cache user data
        _icons[entry.user_id] = entry.icon
        _usernames[entry.user_id] = entry.username

        -- Remove flag from timestamp
        if sub(entry.extra, 1, 1) == "r" then
            data[1] = tonum(sub(data[1], 2))

        -- Decompress packet
        else
            data[1] = tonum(data[1])
            data[2] = unpod("b64:"..(data[2] or "0"))
        end

        -- Outgoing packets
        if id == entry.user_id and not include_sent then
            -- Skip

        -- Old packets
        elseif has(_old, entry.extra) then
            -- Skip

        -- New packet
        elseif #data==2 then
            add(_old, entry.extra)
            add(_packets, {
                user_id=entry.user_id,
                username=entry.username,
                timestamp=data[1],
                extra=data[2],
            })
        end
    end

end

-- Updates the table that packets will be sent through
-- Can be used for room id's
function scoresub_set_table(name)
    _table=name
end

-- Returns the current scoresub "ping"
-- i.e. The number of packets sent ever
function scoresub_get_ping()
    return _highest
end

-- Returns the icon attached to a user id if it has been loaded.
function scoresub_get_icon(user_id)
    return _icons[user_id]
end

-- Returns the username attached to a user id if it has been loaded.
function scoresub_get_username(user_id)
    return _usernames[user_id]
end

-- Packet Handling ==============================

-- Sends a packet string via scoresub
-- A timestamp is appended to the beginning of the string
-- Returns the generated packet "timestamp:str"
-- str <string>  A string of data to send via scoresub
-- raw <boolean> Whether to leave the string uncompressed.
function scoresub_send_packet(str, raw)

    -- Manual rate limiting (2 packets per second)
    if _rate_limit\1 < t()\1 then
        _rate_limit = t()
        _rate_sent = 0
    end
    if _rate_sent >= 2 then return end
    _rate_sent += 1

    -- Format the packet
    if not raw then str = sub(pod(str, 0x7), 12, -3) end
    str = string.format("%s:%s", flr(stat(86)), str)

    -- Set flag at start
    if raw then str = "r"..str end

    -- Send data
    scoresub(_table, _highest+1, str)
    return str
end

-- Returns the number of unprocessed packets
-- being handled by scoresub
function scoresub_packet_count()
    return #_packets
end

-- Pops and returns the first packet from the list
-- A packet is a table with the following fields:
-- - user_id:   A string that uniquely identifies the player
-- - username:  The player's username (might change over time)
-- - timestamp: An epoch timestamp
-- - extra:     The extra string
function scoresub_get_packet()
    return deli(_packets, 1)
end