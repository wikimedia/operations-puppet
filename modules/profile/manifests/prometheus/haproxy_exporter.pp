# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::haproxy_exporter(
    Stdlib::Port $listen_port = lookup('listen_port'),
){
    class {'::prometheus::haproxy_exporter':
        listen_port => $listen_port
    }
}
