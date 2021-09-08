# http_request
#   time to wait for a complete HTTP request. It only applies to the header part
#   of the HTTP request (unless option http-buffer-request is used)
# keep_alive
#   set the maximum allowed time to wait for a new HTTP request to appear
# client
#   set the maximum inactivity time on the client side
# client_fin
#   inactivity timeout on the client side for half-closed connections
# connect
#   connect timeout against a backend server
# server
#   set the maximum inactivity time on the server side
# tunnel
#   this timeout is used when a connection is upgraded (e.g.
#   when switching to the WebSocket protocol) or after the first response when no
#   keepalive/close option is specified.
type Haproxy::Timeout = Struct[{
    'http_request' => Integer[0],
    'keep_alive'   => Integer[0],
    'client'       => Integer[0],
    'client_fin'   => Integer[0],
    'connect'      => Integer[0],
    'server'       => Integer[0],
    'tunnel'       => Integer[0],
}]
