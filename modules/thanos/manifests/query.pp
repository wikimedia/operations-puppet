# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::query
#
# Thanos query exposes a Prometheus-compatible query API over HTTP. Results are
# gathered from all configured Thanos StoreAPI endpoints.
#
# = Parameters
# [*http_port*] The port to listen on for HTTP
# [*replica_label*] The Prometheus label to use for deduplicating results
# [*query_url*] The publicly-reachable Thanos query URL to attach to alerts
# [*sd_files*] The file glob used to discover Thanos StoreAPI endpoints
# [*tracing_enabled*] Self explanatory
# [*request_debug*] Enable request debug logging
# [*memlimit_ratio*] Set GOMEMLIMIT to system/container memory * ratio. Use 0.0 to disable.

class thanos::query (
    Stdlib::Port::Unprivileged $http_port,
    String $replica_label = 'replica',
    Optional[Stdlib::HTTPSUrl] $query_url = undef,
    String $sd_files = '/etc/thanos-query/stores/*.yml',
    Boolean $tracing_enabled = false,
    Boolean $request_debug = false,
    Float[0, 1] $memlimit_ratio = 0.7,
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

    $logging_config = @("CONFIG")
        http:
          options:
            level: DEBUG
            decision:
              log_start: true
              log_end: true
        | CONFIG

    file { '/etc/thanos-query/request-logging.yml':
        ensure  => present,
        content => $logging_config,
    }

    $tracing_config_file = '/etc/thanos-query/tracing-config.yml'
    thanos::tracing { $tracing_config_file:
        service_name => $service_name,
        sampler_type => 'parentbasedalwayssample',
        notify       => Service[$service_name],
    }

    $logging_cmdline = $request_debug ? {
        true    => '--log.level=debug --request.logging-config-file=/etc/thanos-query/request-logging.yml',
        default => '',
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
