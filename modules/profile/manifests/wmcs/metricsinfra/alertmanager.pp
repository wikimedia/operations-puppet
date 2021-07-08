class profile::wmcs::metricsinfra::alertmanager (
    Array[Hash]  $projects = lookup('profile::wmcs::metricsinfra::monitored_projects'),
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
) {
    $base_path = '/etc/prometheus/alertmanager'

    # Prometheus alert manager service setup and config
    package { 'prometheus-alertmanager':
        ensure => present,
    }

    service { 'prometheus-alertmanager':
        ensure => running,
    }

    exec { 'alertmanager-reload':
        command     => '/bin/systemctl reload prometheus-alertmanager',
        refreshonly => true,
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
        owner  => 'root',
        group  => 'root',
    }

    file { "${base_path}/alertmanager.yml":
        content => template('profile/wmcs/metricsinfra/alertmanager.yml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['alertmanager-reload'],
    }
}
