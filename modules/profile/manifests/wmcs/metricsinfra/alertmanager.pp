class profile::wmcs::metricsinfra::alertmanager (
    Array[Hash]  $projects = lookup('profile::wmcs::metricsinfra::monitored_projects'),
) {
    # Base Prometheus data and configuration path
    $base_path = '/srv/prometheus/cloud'

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

    file { '/etc/default/prometheus-alertmanager':
        content => template('profile/wmcs/metricsinfra/prometheus-alertmanager-defaults.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['alertmanager-restart'],
    }

    file { "${base_path}/alertmanager.yml":
        content => template('profile/wmcs/metricsinfra/alertmanager.yml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['alertmanager-reload'],
    }

    # Expose alertmanager as /.alertmanager via apache reverse proxy
    file { '/etc/apache2/prometheus.d/alertmanager.conf':
        ensure  => present,
        content => template('profile/wmcs/metricsinfra/alertmanager-apache.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
