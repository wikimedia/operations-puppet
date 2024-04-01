# SPDX-License-Identifier: Apache-2.0
# = Class: libraryupgrader
#
# This class sets up libraryupgrader aka LibUp
# https://www.mediawiki.org/wiki/Libraryupgrader
#
# @param enable_workers whether to enable the worker units
class libraryupgrader (
    Stdlib::Unixpath $base_dir,
    Boolean          $enable_workers,
) {
    $data_dir  = "${base_dir}/data"
    $clone_dir  = "${base_dir}/libraryupgrader"

    ensure_packages(['python3-venv', 'rabbitmq-server'])

    package { 'docker.io':
        ensure => present,
    }

    systemd::sysuser { 'libup':
        additional_groups => ['docker'],
    }

    file { $data_dir:
        ensure => directory,
        owner  => 'libup',
        group  => 'libup',
        mode   => '0755',
    }

    git::clone { 'repos/ci-tools/libup':
        ensure    => present,
        source    => 'gitlab',
        directory => $clone_dir,
        branch    => 'master',
        owner     => 'libup',
        group     => 'libup',
        require   => User['libup'],
    }

    # Create virtualenv
    exec { 'create virtualenv':
        command => '/usr/bin/python3 -m venv venv',
        cwd     => $clone_dir,
        user    => 'libup',
        creates => "${clone_dir}/venv/bin/python",
        require => [
            Package['python3-venv'],
            Git::Clone['repos/ci-tools/libup'],
        ],
    }

    exec { 'install pip and wheel in virtualenv':
        command => "${clone_dir}/venv/bin/pip install -U pip wheel",
        cwd     => $clone_dir,
        user    => 'libup',
        creates => "${clone_dir}/venv/bin/wheel",
        require => Exec['create virtualenv'],
    }

    # Bootstrap initial dependencies
    exec { 'install virtualenv dependencies':
        command => "${clone_dir}/venv/bin/pip install -r requirements.txt",
        cwd     => $clone_dir,
        user    => 'libup',
        # Just one example file created after the deps are installed
        creates => "${clone_dir}/venv/bin/gunicorn",
        require => Exec['install pip and wheel in virtualenv'],
    }

    # Install libup into venv
    exec { 'install libup':
        command => "${clone_dir}/venv/bin/pip install -e .",
        cwd     => $clone_dir,
        user    => 'libup',
        # Just one example file created after libup is installed
        creates => "${clone_dir}/venv/bin/libup-run",
        require => Exec['install virtualenv dependencies'],
    }

    $systemd_ensure = stdlib::ensure($enable_workers)

    systemd::service { 'libup-celery':
        ensure  => $systemd_ensure,
        content => template('libraryupgrader/initscripts/libup-celery.service.erb'),
        require => [
            Exec['install libup'],
            Package['rabbitmq-server'],
        ]
    }

    systemd::service { 'libup-push':
        ensure  => $systemd_ensure,
        content => template('libraryupgrader/initscripts/libup-push.service.erb'),
        require => [
            Exec['install libup'],
            Package['rabbitmq-server'],
        ]
    }

    systemd::service { 'libup-ssh-agent':
        ensure  => present,
        content => template('libraryupgrader/initscripts/libup-ssh-agent.service.erb'),
        require => User['libup'],
    }

    systemd::timer::job { 'libup-run':
        ensure      => $systemd_ensure,
        description => 'Trigger the libup daily run',
        command     => "${clone_dir}/venv/bin/libup-run",
        user        => 'libup',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00',  # Every day at midnight
        },
        require     => Exec['install libup'],
    }
}
