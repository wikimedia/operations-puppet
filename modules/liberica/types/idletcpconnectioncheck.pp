# SPDX-License-Identifier: Apache-2.0
# Liberica Idle TCP Connection healthcheck configuration
# [*type*]
#  String used by liberica to identify Idle TCP connection healthchecks.
#  It must be set to IdleTCPConnectionCheck
# [*timeout*]
#  timeout to perform the HTTP request (5s, 5000ms)
# [*check_period*]
#  time between checks (3s, 3000ms)
# [*reconnect_period*]
#  waiting time between reconnect attempts after a
#  failed attempt (3s, 3000ms)
# [*keepalive_idle*]
#  time that the connection must be idle before the first keep-alive probe
#  is sent (15s, 15000ms)
# [*keepalive_interval*]
#  time between keep-alive probes. (15s, 15000ms)
# [*keepalive_retries*]
#  maximum number of keep-alive probes that can go unanswered before dropping
#  a connection. (3)
type Liberica::IdleTCPConnectionCheck = Struct[{
        'type'               => Enum['IdleTCPConnectionCheck'],
        'timeout'            => String[2],
        'check_period'       => String[2],
        'reconnect_period'   => String[2],
        'keepalive_idle'     => String[2],
        'keepalive_interval' => String[2],
        'keepalive_retries'  => Integer[1],
}]
