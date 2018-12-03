function set_cc_private()
    if ts.client_response.header['Set-Cookie'] then
        ts.client_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
    end
end

function do_remap()
    ts.hook(TS_LUA_HOOK_SEND_RESPONSE_HDR, set_cc_private)
    return 0
end
