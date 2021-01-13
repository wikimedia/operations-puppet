-- Usage:
-- map / https://appservers-rw.discovery.wmnet @plugin=/usr/lib/trafficserver/modules/tslua.so \
--     @pparam=/etc/trafficserver/lua/normalize-path.lua @pparam="3A 2F 40 21 24 28 29 2A 2C 3B" @pparam="5B 5D 26 27 2B 3D"

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

-- For example:
-- DECODESET = Set { "3A", "2F", "40", "21", "24", "28", "29", "2A", "2C", "3B" }
-- ENCODESET = Set { "[", "]", "&", "'", "+", "=" }
local DECODESET, ENCODESET

-- "3A 2F 40" -> Set { "3A", "2F", "40" }
function hexStringToHexSet(str)
    local set = {}
    for i in string.gmatch(str, "%S+") do
        set[i] = true
    end
    return set
end

-- "3A 2F 40" -> Set { ":", "/", "@" }
function hexStringToLiteralSet(str)
    local set = {}
    for i in string.gmatch(str, "%S+") do
        set[string.char(tonumber(i, 16))] = true
    end
    return set
end

-- This happens once at plugin initialization time
function __init__(argtb)
    local decodestring, _ = string.gsub(argtb[1], '"', "")
    DECODESET = hexStringToHexSet(decodestring)

    local encodestring, _ = string.gsub(argtb[2], '"', "")
    ENCODESET = hexStringToLiteralSet(encodestring)
end

function encode(char)
    if ENCODESET[char] then
        return string.format("%%%X", string.byte(char))
    else
        return char
    end
end

function decode(hex)
    hex = string.upper(hex)

    if DECODESET[hex] then
        return string.char(tonumber(hex, 16))
    else
        return "%" .. hex
    end
end

function pathencode(str)
    local output, _ = string.gsub(str, "[^%w]", encode)
    return output
end

function pathdecode(str)
    local output, _ = string.gsub(str, "%%(%x%x)", decode)
    return output
end

-- path = "/wiki/User:Ema%2fProfiling_Python%28Now you know[dude]"
-- return "/wiki/User:Ema/Profiling_Python(Now you know%5Bdude%5D"
function normalize(path)
    return pathencode(pathdecode(path))
end

function remap_hook()
    if ts.client_request.get_method() == "PURGE" then
        local orig_path = ts.client_request.get_uri()
        local modified_path = normalize(orig_path)

        if orig_path ~= modified_path then
            ts.client_request.set_uri(modified_path)
        end
    end
end

function do_remap()
    ts.hook(TS_LUA_HOOK_POST_REMAP, remap_hook)
    return 0
end

-- : / @ ! $ ( ) * , ;
-- DECODESET = hexStringToHexSet("3A 2F 40 21 24 28 29 2A 2C 3B")
-- Set { "[", "]", "&", "'", "+", "=" }
-- ENCODESET = hexStringToLiteralSet("5B 5D 26 27 2B 3D")
-- print(normalize("/wiki/User:Ema%2fProfiling_Python%28Now you know[dude]-test"))
