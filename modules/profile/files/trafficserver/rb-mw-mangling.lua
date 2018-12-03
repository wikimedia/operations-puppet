function remap_hook()
    -- RestBASE mangling
    local orig_path = ts.client_request.get_uri()
    if string.match(orig_path, "^/api/rest_v1/") then
        local host = ts.client_request.header['Host']
        new_path = "/" .. host .. string.gsub(orig_path, "^/api/rest_v1/", "/v1/")
        ts.client_request.set_uri(new_path)
    end

    -- MediaWiki mangling
    if ts.client_request.header['X-Subdomain'] then
        ts.client_request.header['Host'] = ts.client_request.header['x-dt-host']
    end
end

function do_remap()
    ts.hook(TS_LUA_HOOK_POST_REMAP, remap_hook)
    return 0
end
