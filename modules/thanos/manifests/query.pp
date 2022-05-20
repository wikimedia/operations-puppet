# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::query
#
# Thanos query exposes a Prometheus-compatible query API over HTTP. Results are
# gathered from all configured Thanos StoreAPI endpoints.
#
# = Parameters
# [*http_port*] The port to listen on for HTTP
# [*replica_label*] The Prometheus label to use for deduplicating results
# [*sd_files*] The file glob used to discover Thanos StoreAPI endpoints

class thanos::query (
    Stdlib::Port::Unprivileged $http_port,
    String $replica_label = 'replica',
    String $sd_files = '/etc/thanos-query/stores/*.yml',
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $service_name = 'thanos-query'
    $sd_files_path = dirname($sd_files)

    file { ['/etc/thanos-query', $sd_files_path]:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('thanos-query'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
