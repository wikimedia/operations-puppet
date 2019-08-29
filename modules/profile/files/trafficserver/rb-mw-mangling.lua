function remap_hook()
    local orig_uri = ts.client_request.get_uri()

    -- RestBASE mangling
    if string.match(orig_uri, "^/api/rest_v1/") then
        local host = ts.client_request.header['Host']
        new_path = "/" .. host .. string.gsub(orig_uri, "^/api/rest_v1/", "/v1/")
        ts.client_request.set_uri(new_path)
        return
    end

    -- MediaWiki mangling
    if ts.client_request.header['X-Subdomain'] then
        ts.client_request.header['Host'] = ts.client_request.header['x-dt-host']
        return
    end

    -- w.wiki URL shortener rewrite to meta T133485
    if ts.client_request.header['Host'] == "w.wiki" and orig_uri ~= "/" then
        ts.client_request.header['Host'] = "meta.wikimedia.org"
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
