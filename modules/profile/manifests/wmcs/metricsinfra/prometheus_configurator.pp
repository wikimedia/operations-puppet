# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::prometheus_configurator (
    Stdlib::HTTPUrl     $config_manager_url       = lookup('profile::wmcs::metricsinfra::config_manager_url', {default_value => 'http://config-manager.svc.metricsinfra.eqiad1.wikimedia.cloud'}),
    Array[Stdlib::Fqdn] $alertmanager_hosts       = lookup('profile::wmcs::metricsinfra::prometheus_alertmanager_hosts'),
    Array[Hash]         $global_jobs              = lookup('profile::wmcs::metricsinfra::global_jobs'),
    Stdlib::Fqdn        $alertmanager_active_host = lookup('profile::wmcs::metricsinfra::alertmanager_active_host'),
) {
    $gitdir = '/var/lib/git'
    $clone_dir = "${gitdir}/cloud/metricsinfra/prometheus-configurator"

    group { 'prometheus-configurator':
        ensure => present,
        system => true,
    }

    user { 'prometheus-configurator':
        ensure => present,
        system => true,
        gid    => 'prometheus-configurator',
        home   => '/nonexistent',
        # add to prometheus group for access to edit its configuration
        groups => ['prometheus'],
    }

    # at least this time the dependencies are packaged, so no need
    # to do venv tricks here!
    ensure_packages(['python3-requests', 'python3-yaml'])

    wmflib::dir::mkdir_p("${gitdir}/cloud/metricsinfra")

    # TODO: better deployment model (scap, debian, so on) - T288052
    git::clone { 'cloud/metricsinfra/prometheus-configurator':
        ensure    => latest,
        directory => $clone_dir,
        owner     => 'prometheus-configurator',
        group     => 'prometheus-configurator',
        require   => User['prometheus-configurator'],
    }

    file { '/etc/prometheus-configurator':
        ensure => directory,
        owner  => 'prometheus-configurator',
        group  => 'prometheus-configurator',
    }

    $config = {
        manager => {
            url => $config_manager_url,
        },
        openstack => {
            credentials => '/etc/novaobserver.yaml',
        },
        alertmanager_hosts => $alertmanager_hosts.map |Stdlib::Fqdn $host| {
            "${host}:9093"
        },
        alert_routing => {
            irc_base => "http://${alertmanager_active_host}:19190/",
        },
        global_jobs => $global_jobs,
        outputs => [],
        external_rules_files => [
            'alerts_default.yml',
        ],
        external_labels => {
            replica => $::facts['networking']['hostname'],
        },
    }

    file { '/etc/prometheus-configurator/config.yaml':
        ensure  => present,
        owner   => 'prometheus-configurator',
        group   => 'prometheus-configurator',
        content => to_yaml($config),
        mode    => '0440',
    }

    file { '/etc/prometheus-configurator/config.d/':
        ensure => directory,
        owner  => 'prometheus-configurator',
        group  => 'prometheus-configurator',
    }

    systemd::timer::job { 'prometheus-configurator':
        ensure            => present,
        description       => 'Update prometheus configuration from the controller server',
        working_directory => $clone_dir,
        command           => '/usr/bin/python3 scripts/create-prometheus-config --config /etc/prometheus-configurator/config.yaml --config "/etc/prometheus-configurator/config.d/*.yaml"',
        user              => 'prometheus-configurator',
        interval          => [
            {
                'start'    => 'OnBootSec',
                'interval' => '30s',
            },
            {
                'start'    => 'OnUnitInactiveSec',
                'interval' => '300s',
            },
        ],
        environment       => {
            'PYTHONPATH' => $clone_dir,
        },
    }
}
