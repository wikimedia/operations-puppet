# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::alertmanager (
    Array[Stdlib::Fqdn] $alertmanager_hosts = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
    Stdlib::Fqdn        $active_host        = lookup('profile::wmcs::metricsinfra::alertmanager_active_host'),
    Optional[String[1]] $victorops_api_key  = lookup('profile::wmcs::metricsinfra::victorops_api_key', {'default_value' => undef}),
) {
    $base_path = '/etc/prometheus/alertmanager'

    # Prometheus alert manager service setup and config
    package { 'prometheus-alertmanager':
        ensure => present,
    }

    exec { 'alertmanager-restart':
        require     => Package['prometheus-alertmanager'],
        command     => '/bin/systemctl restart prometheus-alertmanager',
        refreshonly => true,
    }

    $peers = $alertmanager_hosts.filter |Stdlib::Fqdn $host| {
        $host != $::fqdn
    }.map |Stdlib::Fqdn $host| {
        "${host}:9094"
    }

    file { '/etc/default/prometheus-alertmanager':
        content => epp(
          'profile/wmcs/metricsinfra/prometheus-alertmanager-defaults.epp',
          {
            'base_path'      => $base_path,
            'listen_address' => $::ipaddress,
            'peers'          => $peers,
          }
        ),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Exec['alertmanager-restart'],
    }

    # prometheus_configurator will manage the directory contents, but
    # it still needs to exist and be writable
    file { $base_path:
        ensure  => directory,
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0775',
        require => Package['prometheus-alertmanager'],
    }

    # TODO: instead of providing the config base, split into small
    # parts and fit into the base prometheus_configurator.pp config
    file { '/etc/prometheus-configurator/config.d/alertmanager-base.yaml':
        content => epp('profile/wmcs/metricsinfra/alertmanager.yml.epp', {
            victorops_api_key => $victorops_api_key,
        }),
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
        enable => true,
    }
}
