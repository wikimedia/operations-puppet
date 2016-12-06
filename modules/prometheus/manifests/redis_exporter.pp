# Prometheus Redis server metrics exporter.

# === Parameters
#
# [*$instance*]
#  The instance name to use, e.g. as the service suffix
#
# [*$arguments*]
#  The command line arguments to run prometheus-redis-exporter
#
# [*$redis_password*]
#  The Redis instance password
#
# [*$listen_address*]
#  The host:port tuple to listen on, host can be omitted.

define prometheus::redis_exporter (
    $instance = $title,
    $arguments = '',
    $redis_password = '',
    $listen_address = ':9121',
) {
    require_package('prometheus-redis-exporter')
    $service_name = "prometheus-redis-exporter@${instance}"

    exec { "mask_default_redis_exporter_${instance}":
        command => '/bin/systemctl mask prometheus-redis-exporter.service',
        creates => '/etc/systemd/system/prometheus-redis-exporter.service',
    }

    file { "/etc/default/${service_name}":
        ensure  => present,
        mode    => '0400',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"\nREDIS_PASSWORD=\"${redis_password}\"",
        notify  => Service[$service_name],
    }

    systemd::unit { $service_name:
        ensure  => present,
        content => systemd_template('prometheus-redis-exporter@')
        restart => true,
        require => Package['prometheus-redis-exporter'],
    }
}
