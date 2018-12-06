function do_global_read_response()
    if ts.server_response.header['Set-Cookie'] then
        ts.server_response.header['Cache-Control'] = 'private, max-age=0, s-maxage=0'
        ts.error("Setting CC:private on response with Set-Cookie for uri " ..  ts.client_request.get_uri())
    end
    return 0
end
