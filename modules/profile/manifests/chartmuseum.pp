# SPDX-License-Identifier: Apache-2.0
# == Class: profile::chartmuseum
#
# This class sets up a ChartMuseum instance with swift storage back-end.
#
# Envoy will be run as tls-terminator, so ChartMuseum may listen on localhost
# only.
#
# === Parameters
# [*hostname*] The hostname to use in Host header for monitoring.
#
# [*swift_backend*] Optional configuration of a Swift storage backend (URL,
#                   container name, username and password). If this parameter is
#                   not set, local storage in "/var/lib/chartmuseum" is used.
#
# [*basic_auth*] Optional username and password to enable HTTP basic auth.
#
class profile::chartmuseum(
    Stdlib::Fqdn                        $hostname                = lookup('profile::chartmuseum::hostname'),
    Optional[ChartMuseum::SwiftBackend] $swift_backend           = lookup('profile::chartmuseum::swift_backend'),
    Optional[ChartMuseum::BasicAuth]    $basic_auth              = lookup('profile::chartmuseum::basic_auth'),
){
    require ::profile::tlsproxy::envoy # TLS termination

    $listen_host = 'localhost'
    $listen_port = 8080
    $repository_depth = 1
    $disable_delete = true
    $disable_force_overwrite = true
    $allow_anonymous_get = true
    $debug = false

    class { '::chartmuseum':
        listen_host             => $listen_host,
        listen_port             => $listen_port,
        repository_depth        => $repository_depth,
        disable_delete          => $disable_delete,
        disable_force_overwrite => $disable_force_overwrite,
        allow_anonymous_get     => $allow_anonymous_get,
        swift_backend           => $swift_backend,
        basic_auth              => $basic_auth,
        debug                   => $debug,
    }

    # Monitoring
    $monitoring_notes_url = 'https://wikitech.wikimedia.org/wiki/ChartMuseum'
    nrpe::monitor_systemd_unit_state{ 'chartmuseum.service':
        ensure      => present,
        description => 'Check that ChartMuseum is running',
        retries     => 2,
        notes_url   => $monitoring_notes_url,
    }

    monitoring::service { 'check_chartmuseum_http':
        description   => 'ChartMuseum HTTP',
        check_command => "check_https_url_for_string!${hostname}!/health!true",
        notes_url     => $monitoring_notes_url,
    }

    monitoring::service { 'check_chartmuseum_https_expiry':
        description   => 'ChartMuseum HTTP certificate expiry',
        check_command => "check_https_expiry!${hostname}!443",
        notes_url     => $monitoring_notes_url,
    }

    # Setup a to package and sync (new) charts automatically
    #
    package { 'python3-docker-report':
        ensure => present,
    }
    package { 'helm3':
        ensure => present,
    }

    # Clone deployment-charts repository
    $charts_git = '/srv/deployment-charts'
    git::clone { 'operations/deployment-charts':
        ensure    => 'present',
        owner     => 'chartmuseum',
        group     => 'chartmuseum',
        directory => $charts_git,
        require   => Class['chartmuseum'],
    }

    # Provide chartmuseum username and passwort for the timer
    $defaults_file = '/etc/default/helm-chartctl-package-all'
    file { $defaults_file:
        ensure  => file,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        content => template('profile/chartmuseum/helm-chartctl.defaults.erb'),
        notify  => Systemd::Timer::Job['helm-chartctl-package-all'],
    }

    # Pull the latest changes from git, package and push new charts every 2 minutes
    $cmd_pull = '/usr/bin/git pull'
    $cmd_package = "/usr/bin/helm-chartctl --cm-url http://${listen_host}:${listen_port} walk ${charts_git}/charts stable"
    systemd::timer::job { 'helm-chartctl-package-all':
        ensure           => present,
        description      => 'Package and push new charts to local Chartmuseum instance',
        command          => "/bin/sh -c 'cd ${charts_git} && ${cmd_pull} && ${cmd_package}'",
        environment_file => $defaults_file,
        user             => 'chartmuseum',
        logging_enabled  => false,
        require          => [Class['chartmuseum'], Git::Clone['operations/deployment-charts'], Package['python3-docker-report'], File[$defaults_file]],
        interval         => {
            # We don't care about when this runs, as long as it runs every 2 minutes.
            # We also explicitly *don't* want to synchronize its execution across hosts,
            # as OnCalendar would do, and this should have some natural splay.
            'start'    => 'OnUnitInactiveSec',
            'interval' => '120s',
        },
    }
}
