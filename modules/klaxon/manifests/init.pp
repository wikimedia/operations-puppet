# SPDX-License-Identifier: Apache-2.0
# == Class: klaxon
#
# Install and configure klaxon, a simple webapp for users to page SRE.
class klaxon(
    Klaxon::Klaxon_config $config,
    String $escalation_policy_slug,
    Stdlib::Unixpath $install_dir = '/srv/klaxon',
    Stdlib::Port $port = 4667,
) {
    ensure_packages(['gunicorn3', 'python3-cachetools', 'python3-dateutil', 'python3-flask', 'python3-requests'])

    $environ_file = '/var/lib/klaxon/environ_file'

    # TODO: a better deployment model.
    git::clone { 'operations/software/klaxon':
        ensure    => latest,
        directory => $install_dir,
        branch    => 'master',
    }

    systemd::sysuser { 'klaxon':
        home_dir => '/var/lib/klaxon',
        shell    => '/bin/bash',
    }

    file { $environ_file:
        ensure  => 'file',
        owner   => 'root',
        group   => 'klaxon',
        mode    => '0440',
        require => User['klaxon'],
        content => template('klaxon/environ_file.erb'),
    }

    systemd::service { 'klaxon':
        ensure    => 'present',
        content   => systemd_template('klaxon'),
        restart   => true,
        subscribe => [
            Exec['git_pull_operations/software/klaxon'],
            File[$environ_file],
        ],
        require   => [
          User['klaxon'],
        ],
    }

    profile::auto_restarts::service { 'klaxon': }

    systemd::service { 'vo-escalate.service':
        ensure    => 'present',
        content   => systemd_template('vo-escalate'),
        restart   => true,
        subscribe => [
            Exec['git_pull_operations/software/klaxon'],
            File[$environ_file],
        ],
        require   => [
          User['klaxon'],
        ],
    }

    systemd::timer { 'vo-escalate':
        timer_intervals => [
            { 'start'    => 'OnCalendar',
              'interval' => '*:*:00/15', # every 15s
            }],
        splay           => 7, # Timer runs on all (two) alerting hosts
    }
}
