# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::mcrouter_exporter (
    Stdlib::Port        $mcrouter_port    = lookup('profile::prometheus::mcrouter_exporter::mcrouter_port'),
    Stdlib::Port        $listen_port      = lookup('profile::prometheus::mcrouter_exporter::listen_port'),
) {
    prometheus::mcrouter_exporter { 'default':
        arguments => "-mcrouter.address localhost:${mcrouter_port} -web.listen-address :${listen_port} -mcrouter.server_metrics",
    }

    profile::auto_restarts::service { 'prometheus-mcrouter-exporter': }
}
