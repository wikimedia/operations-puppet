function set_cc_private()
    if ts.server_response.header['Set-Cookie'] then
        ts.server_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
        ts.error("Setting CC:private on response with Set-Cookie for uri " ..  ts.client_request.get_uri())
    end
end

function do_remap()
    ts.hook(TS_LUA_HOOK_READ_RESPONSE_HDR, set_cc_private)
    return 0
end
