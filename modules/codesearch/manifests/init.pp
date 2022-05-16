# SPDX-License-Identifier: Apache-2.0
# = Class: codesearch
#
# This class sets up the basics needed for MediaWiki code search
# hosted at codesearch.wmcloud.org
#
class codesearch(
    Optional[Stdlib::Unixpath] $base_dir = undefined,
    Hash[String, Integer] $ports = undefined,
){
    $hound_dir  = "${base_dir}/hound"
    $clone_dir  = "${base_dir}/codesearch"

    apt::package_from_component { 'thirdparty-kubeadm-k8s':
        component => 'thirdparty/kubeadm-k8s-1-15',
        packages  => ['docker-ce'],
    }

    ensure_packages([
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
    ])

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

    file { $hound_dir:
        ensure => directory,
        owner  => 'codesearch',
        group  => 'codesearch',
        mode   => '0755',
    }

    group { 'codesearch':
        ensure => present,
        name   => 'codesearch',
        system => true,
    }

    user { 'codesearch':
        ensure  => present,
        system  => true,
        groups  => 'docker',
        require => Package['docker-ce'],
    }

    git::clone {'labs/codesearch':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
        require   => User['codesearch'],
        owner     => 'codesearch',
        group     => 'codesearch',
    }

    file { '/etc/hound-gitconfig':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/codesearch/hound-gitconfig',
    }

    systemd::timer::job { 'codesearch-write-config':
        description => 'Generate hound configuration files',
        command     => "${clone_dir}/write_config.py --restart",
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 06:00:00',  # Every day before Europe wakes up
        },
        require     => [
            Git::Clone['labs/codesearch'],
            User['codesearch'],
        ],
    }

    systemd::service { 'hound_proxy':
        ensure    => present,
        content   => template('codesearch/initscripts/hound_proxy.service.erb'),
        restart   => true,
        subscribe => File['/etc/codesearch_ports.json'],
        require   => [
            Git::Clone['labs/codesearch'],
            Package['gunicorn3'],
            File['/etc/codesearch_ports.json'],
        ]
    }

    systemd::service { 'codesearch-frontend':
        ensure  => present,
        content => template('codesearch/initscripts/codesearch-frontend.service.erb'),
        require => [
            Git::Clone['labs/codesearch'],
            Package['docker-ce'],
        ]
    }

    file { '/etc/codesearch_ports.json':
        ensure  => present,
        content => to_json_pretty($ports),
        owner   => 'codesearch',
        require => User['codesearch'],
    }

    $ports.each |String $name, Integer $port| {
        systemd::service { "hound-${name}":
            ensure  => present,
            content => template('codesearch/initscripts/hound.service.erb'),
            restart => true,
            require => [
                Package['docker-ce'],
                Systemd::Service['hound_proxy'],
                Systemd::Timer::Job['codesearch-write-config'],
                File['/etc/hound-gitconfig'],
            ]
        }
    }
}
