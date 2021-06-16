class profile::wmcs::metricsinfra::alertmanager (
    Array[Hash]  $projects = lookup('profile::wmcs::metricsinfra::monitored_projects'),
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
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

    file { $base_path:
        ensure => directory,
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    file { '/etc/prometheus-configurator/config.d/alertmanager-base.yaml':
        content => template('profile/wmcs/metricsinfra/alertmanager.yml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['prometheus-configurator'],
    }

    profile::wmcs::metricsinfra::prometheus_configurator::output { 'alertmanager':
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
