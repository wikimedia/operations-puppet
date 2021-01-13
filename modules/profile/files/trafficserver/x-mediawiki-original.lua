--[[
 Set X-MediaWiki-Original based on the request URI.

 For example, the following request URI:
  /wikipedia/commons/thumb/3/37/Home_Albert_Einstein_1895.jpg/200px-Home_Albert_Einstein_1895.jpg

 Will result in X-MediaWiki-Original being set to:
  /wikipedia/commons/3/37/Home_Albert_Einstein_1895.jpg
]]

require 'string'

-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

function gen_x_mediawiki_original(uri)
    if string.match(uri, "^/+[^/]+/[^/]+/thumb/[^/]+/[^/]+/[^/]+/[0-9]+px-") then
        prefix, postfix = string.match(uri, "^(/+[^/]+/[^/]+/)thumb/([^/]+/[^/]+/[^/]+).*$")
        ts.client_response.header['X-MediaWiki-Original'] = prefix .. postfix
    end
end

function remap_hook()
    local uri = ts.client_request.get_uri() or ''
    gen_x_mediawiki_original(uri)
end

function do_remap()
    ts.hook(TS_LUA_HOOK_SEND_RESPONSE_HDR, remap_hook)
    return 0
end
