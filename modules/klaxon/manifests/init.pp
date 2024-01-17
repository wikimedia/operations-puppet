# SPDX-License-Identifier: Apache-2.0
# @summary Install and configure klaxon, a simple webapp for users to page SRE.
# @param config the klaxon config
# @param escalation_policy_slug The slug for the escalation policy
# @param install_dir where to install klaxon
# @param port the port klaxon runs on
class klaxon (
    Klaxon::Klaxon_config $config,
    String $escalation_policy_slug,
    Stdlib::Unixpath $install_dir = '/srv/klaxon',
    Stdlib::Port $port = 4667,
) {
    $gunicorn_package = debian::codename::le('buster') ? {
        true    => 'gunicorn3',
        default => 'gunicorn',
    }

    ensure_packages([$gunicorn_package, 'python3-cachetools', 'python3-dateutil', 'python3-flask', 'python3-requests'])

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

    file { '/var/lib/klaxon':
        ensure  => directory,
        owner   => 'klaxon',
        group   => 'klaxon',
        mode    => '0755',
        require => User['klaxon'],
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

    $command = "/usr/bin/python3 klaxon/victorops.py escalate_unpaged ${escalation_policy_slug}"
    systemd::timer::job { 'vo-escalate':
        interval          => [{ 'start' => 'OnCalendar', 'interval' => '*:*:00/15' }], # every 15s
        description       => 'Escalate VO unpaged incidents',
        command           => $command,
        user              => 'klaxon',
        group             => 'klaxon',
        private_tmp       => true,
        timeout_start_sec => 15,
        environment_file  => $environ_file,
        environment       => { 'PYTHONPATH' => $install_dir },
        working_directory => $install_dir,
        splay             => 7, # Timer runs on all (two) alerting hosts
    }
}
