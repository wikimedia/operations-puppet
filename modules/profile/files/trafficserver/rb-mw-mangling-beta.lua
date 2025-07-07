-- SPDX-License-Identifier: Apache-2.0
-- The JIT compiler is causing severe performance issues:
-- https://phabricator.wikimedia.org/T265625
jit.off(true, true)

-- Beta Cluster-specific extension to rb-mw-mangling.lua
function remap_hook()
    local orig_uri = ts.client_request.get_uri()

    -- w.beta.wmcloud.org URL shortener rewrite T396012
    if ts.client_request.header['Host'] == "w.beta.wmcloud.org" and orig_uri ~= "/" then
        ts.client_request.header['Host'] = "en.wikipedia.beta.wmflabs.org"
        ts.client_request.set_uri("/wiki/Special:UrlRedirector" .. orig_uri)
        return
    end
end

function do_remap()
    -- Use TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, so that the mangling happens
    -- after cache lookup and before fetching the response from the origin
    ts.hook(TS_LUA_HOOK_CACHE_LOOKUP_COMPLETE, remap_hook)
    return 0
end
