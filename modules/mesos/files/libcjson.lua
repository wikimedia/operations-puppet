-- Source: https://github.com/bungle/lua-resty-libcjson
-- Copyright (c) 2014, Aapo Talvensaari
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this
-- list of conditions and the following disclaimer.
--
-- Redistributions in binary form must reproduce the above copyright notice, this
-- list of conditions and the following disclaimer in the documentation and/or
-- other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
local ffi        = require "ffi"
local ffi_new    = ffi.new
local ffi_typeof = ffi.typeof
local ffi_cdef   = ffi.cdef
local ffi_load   = ffi.load
local ffi_str    = ffi.string
local ffi_gc     = ffi.gc
local next       = next
local floor      = math.floor
local max        = math.max
local type       = type
local next       = next
local pairs      = pairs
local ipairs     = ipairs
local null       = {}
if ngx and ngx.null then null = ngx.null end
ffi_cdef[[
typedef struct cJSON {
    struct cJSON *next, *prev;
    struct cJSON *child;
    int    type;
    char  *valuestring;
    int    valueint;
    double valuedouble;
    char  *string;
} cJSON;
cJSON *cJSON_Parse(const char *value);
char  *cJSON_Print(cJSON *item);
char  *cJSON_PrintUnformatted(cJSON *item);
void   cJSON_Delete(cJSON *c);
int    cJSON_GetArraySize(cJSON *array);
cJSON *cJSON_CreateNull(void);
cJSON *cJSON_CreateTrue(void);
cJSON *cJSON_CreateFalse(void);
cJSON *cJSON_CreateBool(int b);
cJSON *cJSON_CreateNumber(double num);
cJSON *cJSON_CreateString(const char *string);
cJSON *cJSON_CreateArray(void);
cJSON *cJSON_CreateObject(void);
void   cJSON_AddItemToArray(cJSON *array, cJSON *item);
void   cJSON_AddItemToObject(cJSON *object,const char *string,cJSON *item);
void   cJSON_Minify(char *json);
]]
local ok, newtab = pcall(require, "table.new")
if not ok then newtab = function() return {} end end
local cjson = ffi_load("libcjson")
local json = newtab(0, 6)
local char_t = ffi_typeof("char[?]")
local mt_arr = { __index = { __jsontype = "array"  }}
local mt_obj = { __index = { __jsontype = "object" }}
local ctrue, cfalse, cnull = cjson.cJSON_CreateTrue(), cjson.cJSON_CreateFalse(), cjson.cJSON_CreateNull()
local function is_array(t)
    local m, c = 0, 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 0 or floor(k) ~= k then return false end
        m = max(m, k)
        c = c + 1
    end
    return c == m
end
function json.decval(j)
    local t = j.type
    if t == 0 then return false end
    if t == 1 then return true end
    if t == 2 then return null end
    if t == 3 then return j.valuedouble end
    if t == 4 then return ffi_str(j.valuestring) end
    if t == 5 then return setmetatable(json.parse(j.child, newtab(cjson.cJSON_GetArraySize(j), 0)) or {}, mt_arr) end
    if t == 6 then return setmetatable(json.parse(j.child, newtab(0, cjson.cJSON_GetArraySize(j))) or {}, mt_obj) end
    return nil
end
function json.parse(j, r)
    if j == nil then return nil end
    local c = j
    repeat
        r[c.string ~= nil and ffi_str(c.string) or #r + 1] = json.decval(c)
        c = c.next
    until c == nil
    return r
end
function json.decode(value)
    if type(value) ~= "string" then return value end
    local j = ffi_gc(cjson.cJSON_Parse(value), cjson.cJSON_Delete)
    if j == nil then return nil  end
    local t = j.type
    if t == 5 then return setmetatable(json.parse(j.child, newtab(cjson.cJSON_GetArraySize(j), 0)) or {}, mt_arr) end
    if t == 6 then return setmetatable(json.parse(j.child, newtab(0, cjson.cJSON_GetArraySize(j))) or {}, mt_obj) end
    return json.decval(j)
end
function json.encval(value)
    local  t = type(value)
    if t == "string"  then return cjson.cJSON_CreateString(value) end
    if t == "number"  then return cjson.cJSON_CreateNumber(value) end
    if t == "boolean" then return value and ctrue or cfalse       end
    if t == "table" then
        if next(value) == nil then return (getmetatable(value) ~= mt_obj and is_array(value)) and cjson.cJSON_CreateArray() or cjson.cJSON_CreateObject() end
        if getmetatable(value) ~= mt_obj and is_array(value) then
            local j = cjson.cJSON_CreateArray()
            for _, v in ipairs(value) do
                cjson.cJSON_AddItemToArray(j[0], json.encval(v))
            end
            return j
        end
        local j = cjson.cJSON_CreateObject()
        for k, v in pairs(value) do
            cjson.cJSON_AddItemToObject(j[0], type(k) ~= "string" and tostring(k) or k, json.encval(v))
        end
        return j
    end
    return cnull
end
function json.encode(value, formatted)
    local j = ffi_gc(json.encval(value), cjson.cJSON_Delete)
    if j == nil then return nil end
    return formatted ~= false and ffi_str(cjson.cJSON_Print(j)) or ffi_str(cjson.cJSON_PrintUnformatted(j))
end
function json.minify(value)
    local t = type(value) ~= "string" and json.encode(t) or value
    local m = ffi_new(char_t, #t, t)
    cjson.cJSON_Minify(m)
    return ffi_str(m)
end
return {
    decode = json.decode,
    encode = json.encode,
    minify = json.minify,
    array  = mt_arr,
    object = mt_obj,
    null   = null
}
