# Prometheus Redis server metrics exporter.
#
# === Parameters
#
# [*$instance*]
#  The instance name to use, e.g. as the service suffix.
#
# [*$arguments*]
#  The command line arguments to run prometheus-redis-exporter.
#
# [*$password*]
#  The Redis instance password.
#
# [*$hostname*]
#  The host to listen on. The host/port combination will also be used to generate Prometheus
#  targets.
#
# [*$port*]
#  The port to listen on.

define prometheus::redis_exporter (
    $instance = $title,
    $arguments = '',
    $password = '',
    $hostname = $::hostname,
    $port = '9121'
) {
    require_package('prometheus-redis-exporter')

    $service_name = "prometheus-redis-exporter@${instance}"
    $listen_address = "${hostname}:${port}"

    # We're going with multiple prometheus-redis-exporter, mask and stop the default single-instance one.
    exec { "mask_default_redis_exporter_${instance}":
        command => '/bin/systemctl mask prometheus-redis-exporter.service ; /bin/systemctl stop prometheus-redis-exporter.service',
        creates => '/etc/systemd/system/prometheus-redis-exporter.service',
    }

    file { "/etc/default/${service_name}":
        ensure    => present,
        mode      => '0400',
        owner     => 'root',
        group     => 'root',
        content   => "ARGS=\"-redis.addr localhost:${instance} ${arguments}\"\nREDIS_PASSWORD=\"${password}\"",
        show_diff => false,
        notify    => Systemd::Service[$service_name],
    }

    systemd::service { $service_name:
        ensure  => present,
        content => systemd_template('prometheus-redis-exporter@'),
        restart => true,
        require => Package['prometheus-redis-exporter'],
    }
}
