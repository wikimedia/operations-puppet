-- SPDX-License-Identifier: Apache-2.0
-- NGINX Lua filter for the hcaptcha proxy
-- to only allow Set-Cookie headers for the hmt_id cookie.

local h = ngx.header["Set-Cookie"]
if not h then
    return
end
if type(h) == "table" then
    local filtered = {}
    for _, v in ipairs(h) do
        if string.find(v, "hmt_id=") then
            table.insert(filtered, v)
        end
    end
    ngx.header["Set-Cookie"] = filtered
else
    if not string.find(h, "hmt_id=") then
        ngx.header["Set-Cookie"] = nil
    end
end
