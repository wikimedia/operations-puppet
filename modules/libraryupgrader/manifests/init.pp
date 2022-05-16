# SPDX-License-Identifier: Apache-2.0
# = Class: libraryupgrader
#
# This class sets up libraryupgrader aka LibUp
# https://www.mediawiki.org/wiki/Libraryupgrader
#
class libraryupgrader(
    Optional[Stdlib::Unixpath] $base_dir = undef
){
    $data_dir  = "${base_dir}/data"
    $clone_dir  = "${base_dir}/libraryupgrader"

    ensure_packages(['virtualenv', 'rabbitmq-server'])

    apt::package_from_component { 'thirdparty-kubeadm-k8s':
        component => 'thirdparty/kubeadm-k8s-1-15',
        packages  => ['docker-ce'],
    }

    if debian::codename::eq('buster') {
        # We need iptables 1.8.3+ for compatibility with docker
        # (see comments on <https://gerrit.wikimedia.org/r/565752>)
        apt::pin { 'iptables':
            pin      => 'release a=buster-backports',
            package  => 'iptables',
            priority => 1001,
            before   => Package['docker-ce'],
        }
    }

    group { 'libup':
        ensure => present,
        name   => 'libup',
        system => true,
    }

    user { 'libup':
        ensure  => present,
        system  => true,
        groups  => 'docker',
        require => Package['docker-ce'],
    }

    file { $data_dir:
        ensure => directory,
        owner  => 'libup',
        group  => 'libup',
        mode   => '0755',
    }

    git::clone {'labs/libraryupgrader':
        ensure    => present,
        directory => $clone_dir,
        branch    => 'master',
        owner     => 'libup',
        group     => 'libup',
        require   => User['libup'],
    }

    # Create virtualenv
    exec { 'create virtualenv':
        command => '/usr/bin/virtualenv -p python3 venv',
        cwd     => $clone_dir,
        user    => 'libup',
        creates => "${clone_dir}/venv/bin/python",
        require => [
            Package['virtualenv'],
            Git::Clone['labs/libraryupgrader'],
        ],
    }

    # Bootstrap initial dependencies
    exec { 'install virtualenv dependencies':
        command => "${clone_dir}/venv/bin/pip install -r requirements.txt",
        cwd     => $clone_dir,
        user    => 'libup',
        # Just one example file created after the deps are installed
        creates => "${clone_dir}/venv/bin/gunicorn",
        require => Exec['create virtualenv'],
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

    systemd::service { 'libup-celery':
        ensure  => present,
        content => template('libraryupgrader/initscripts/libup-celery.service.erb'),
        require => [
            Exec['install libup'],
            Package['rabbitmq-server'],
        ]
    }

    systemd::service { 'libup-push':
        ensure  => present,
        content => template('libraryupgrader/initscripts/libup-push.service.erb'),
        require => [
            Exec['install libup'],
            Package['rabbitmq-server'],
        ]
    }

    systemd::service { 'libup-web':
        ensure  => present,
        content => template('libraryupgrader/initscripts/libup-web.service.erb'),
        require => Exec['install libup']
    }

    systemd::service { 'libup-ssh-agent':
        ensure  => present,
        content => template('libraryupgrader/initscripts/libup-ssh-agent.service.erb'),
        require => User['libup'],
    }

    systemd::timer::job { 'libup-run':
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
