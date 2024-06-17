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


    ensure_packages([
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
    ])

    if debian::codename::ge('bookworm') {
        $docker_package='docker.io'
        ensure_packages($docker_package)
    }

    if debian::codename::eq('buster') {
        $docker_package='docker-ce'
        # We need iptables 1.8.3+ for compatibility with docker
        # (see comments on <https://gerrit.wikimedia.org/r/565752>)
        apt::pin { 'iptables':
            pin      => 'release a=buster-backports',
            package  => 'iptables',
            priority => 1001,
            before   => Package[$docker_package],
        }

        apt::package_from_component { 'thirdparty-kubeadm-k8s':
            component => 'thirdparty/kubeadm-k8s-1-15',
            packages  => [$docker_package],
        }

    }

    systemd::sysuser { 'codesearch':
        additional_groups => ['docker'],
    }

    file { $hound_dir:
        ensure => directory,
        owner  => 'codesearch',
        group  => 'codesearch',
        mode   => '0755',
    }

    git::clone {'labs/codesearch':
        ensure    => latest,
        directory => $clone_dir,
        branch    => 'master',
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
            Package[$docker_package],
        ]
    }

    file { '/etc/codesearch_ports.json':
        ensure  => present,
        content => to_json_pretty($ports),
        owner   => 'codesearch',
    }

    $ports.each |String $name, Integer $port| {
        systemd::service { "hound-${name}":
            ensure  => present,
            content => template('codesearch/initscripts/hound.service.erb'),
            restart => true,
            require => [
                Package[$docker_package],
                Systemd::Service['hound_proxy'],
                Systemd::Timer::Job['codesearch-write-config'],
                File['/etc/hound-gitconfig'],
            ]
        }
    }
}
