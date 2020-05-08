# Trafficserver::Network_settings wraps Network settings defined on
# https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/records.config.en.html#network
#
# [*connections_throttle*]
#   The total number of client and origin server connections that the server can handle simultaneously.
#   This is in fact the max number of file descriptors that the traffic_server process can have open at any given time.
#   Roughly 10% of these connections are reserved for origin server connections.
#   If this is set to 0, the throttling logic is disabled.
#
# [*sock_option_flag_in*]
#   Turns different options "on" for the socket handling client connections:
#       Socket options for incoming connections. The provided value is a bitmask:
#           TCP_NODELAY  = 0x1
#           SO_KEEPALIVE = 0x2
#           SO_LINGER    = 0x4
#           TCP_FASTOPEN = 0x8
#
# [*default_inactivity_timeout*]
#   The connection inactivity timeout (in seconds) to apply when Traffic Server detects
#   that no inactivity timeout has been applied by the HTTP state machine.
#
# [*max_connections_in*]
#   Maximum number of incoming connections (ATS defaults to 30000)
#
# [*max_connections_active_in*]
#   Maximum number of active connections (ATS defaults to 10000)
#
type Trafficserver::Network_settings = Struct[{
    'connections_throttle'       => Integer[0],
    'sock_option_flag_in'        => Integer[0, 0xF],
    'default_inactivity_timeout' => Integer[0],
    'max_connections_in'         => Integer[0],
    'max_connections_active_in'  => Integer[0],
}]
