local json = require 'json'
local f = io.open('/var/cache/labsaliaser/labs-ip-aliases.json', 'r')
local f_contents = f:read("*a")
local d = json.decode(f_contents)
io.close(f)
local aliasmapping = d["aliasmapping"]
local extra_records = d["extra_records"]

function postresolve (dq)
    local records = dq:getRecords()
    for key,val in pairs(records)
    do
        content = val:getContent()
        if (aliasmapping[content] and val.type == pdns.A) then
            val:changeContent(aliasmapping[content])
        end
    end
    dq:setRecords(records)
    return true
end

function preresolve(dq)
    for k, v in pairs(extra_records) do
        if dq.qname:equal(k)
        then
            dq:addAnswer(pdns.A, v, 300)
            return true
        end
    end
    return false
end

