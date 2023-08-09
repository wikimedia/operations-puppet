# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::haproxy_exporter(
    Stdlib::Port $listen_port = lookup('listen_port'),
    Wmflib::Ensure $ensure  = lookup('profile::prometheus::haproxy_exporter::ensure', {'default_value' => present}),
){
    class {'::prometheus::haproxy_exporter':
        listen_port => $listen_port,
        ensure      => $ensure,
    }
}
