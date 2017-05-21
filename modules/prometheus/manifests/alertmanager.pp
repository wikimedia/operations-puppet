# == Define: prometheus::alertmanager
#
# XXX
#
# = Parameters
#
# [*listen_address*]
#   Address to listen on, in the form [address]:port.
#
# [*storage_path*]
#   Base path for data storage.
#
# [*external_url*]
#   The URL under which Alertmanager is externally reachable

# XXX config file
class prometheus::alertmanager (
    $listen_address = ':9093',
    $storage_path = '/var/lib/prometheus/alertmanager/',
    $config_file = '/etc/prometheus/alertmanager.yml',
    $external_url = undef,
) {
    requires_os('debian >= jessie')

    require_package('prometheus-alertmanager')

    $service_name = 'prometheus-alertmanager'

    file { $config_file:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Exec["${service_name}-reload"],
        # XXX
        #content => ordered_yaml($prometheus_config),
    }

    exec { "{service_name}-reload":
        command     => "/bin/systemctl reload ${service_name}",
        refreshonly => true,
    }

    base::service_unit { $service_name:
        ensure         => present,
        systemd        => true,
        template_name  => 'prometheus-alertmanager',
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
