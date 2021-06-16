class profile::wmcs::metricsinfra::alertmanager (
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
    Stdlib::Fqdn        $active_host        = lookup('profile::wmcs::metricsinfra::alertmanager_active_host'),
) {
    $base_path = '/etc/prometheus/alertmanager'

    # Prometheus alert manager service setup and config
    package { 'prometheus-alertmanager':
        ensure => present,
    }

    exec { 'alertmanager-restart':
        command     => '/bin/systemctl restart prometheus-alertmanager',
        refreshonly => true,
    }

    $listen_address = $::ipaddress
    $peers = $alertmanager_hosts.filter |Stdlib::Fqdn $host| {
        $host != $::fqdn
    }.map |Stdlib::Fqdn $host| {
        "${host}:9094"
    }

    file { '/etc/default/prometheus-alertmanager':
        content => template('profile/wmcs/metricsinfra/prometheus-alertmanager-defaults.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['alertmanager-restart'],
    }

    # prometheus_configurator will manage the directory contents, but
    # it still needs to exist and be writable
    file { $base_path:
        ensure => directory,
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    # TODO: instead of providing the config base, split into small
    # parts and fit into the base prometheus_configurator.pp config
    file { '/etc/prometheus-configurator/config.d/alertmanager-base.yaml':
        content => template('profile/wmcs/metricsinfra/alertmanager.yml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output_config { 'alertmanager':
        kind    => 'alertmanager',
        options => {
            base_directory  => $base_path,
            units_to_reload => [
                'prometheus-alertmanager.service',
            ]
        },
    }

    service { 'prometheus-alertmanager':
        ensure => running,
    }
}
