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
    $port = '9121',
    Wmflib::Ensure $ensure = 'present',
) {
    $service_name = "prometheus-redis-exporter@${instance}"
    $listen_address = "${hostname}:${port}"

    if $ensure == 'present' {
        ensure_packages('prometheus-redis-exporter')

        Package['prometheus-redis-exporter'] -> Systemd::Service[$service_name]

        # We're going with multiple prometheus-redis-exporter, mask and stop the default single-instance one.
        exec { "mask_default_redis_exporter_${instance}":
            command => '/bin/systemctl mask prometheus-redis-exporter.service ; /bin/systemctl stop prometheus-redis-exporter.service',
            creates => '/etc/systemd/system/prometheus-redis-exporter.service',
        }
    }

    file { "/etc/default/${service_name}":
        ensure    => stdlib::ensure($ensure, 'file'),
        mode      => '0400',
        owner     => 'root',
        group     => 'root',
        content   => "ARGS=\"-redis.addr localhost:${instance} ${arguments}\"\nREDIS_PASSWORD=\"${password}\"",
        show_diff => false,
        notify    => Systemd::Service[$service_name],
    }

    systemd::service { $service_name:
        ensure  => $ensure,
        content => systemd_template('prometheus-redis-exporter@'),
        restart => true,
    }

    profile::auto_restarts::service { $service_name:
        ensure => $ensure,
    }
}
