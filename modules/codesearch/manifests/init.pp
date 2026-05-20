# SPDX-License-Identifier: Apache-2.0
# = Class: codesearch
#
# This class sets up the basics needed for MediaWiki code search
# hosted at codesearch.wmcloud.org
#
class codesearch(
    Optional[Stdlib::Unixpath] $base_dir = undefined,
    Hash[String, Integer] $ports = undefined,
    Integer $lock_file_min_age = undefined,
){
    $hound_dir  = "${base_dir}/hound"
    $clone_dir  = "${base_dir}/codesearch"


    ensure_packages([
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
        'docker.io',
    ])

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

    # To prevent incidents like T421147 we are attempting to
    # find zombie lock files that don't have a corresponding process
    # anymore but have not been cleaned up.

    file { '/usr/local/bin/delete-hound-zombie-locks.sh':
        ensure => file,
        owner  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/codesearch/delete-zombie-locks.sh',
    }

    file { '/etc/hound-delete-zombie-locks.conf':
        ensure  => file,
        owner   => 'root',
        mode    => '0644',
        content => template('codesearch/delete-zombie-locks.conf.erb'),
    }

    systemd::timer::job { 'codesearch-delete-zombie-locks':
        description => 'Delete lock files older than X.',
        command     => '/usr/local/bin/delete-hound-zombie-locks.sh',
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'hourly',
        },
        require     => [
            File['/usr/local/bin/delete-hound-zombie-locks.sh'],
            File['/etc/hound-delete-zombie-locks.conf'],
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
            Package['docker.io'],
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
                Package['docker.io'],
                Systemd::Service['hound_proxy'],
                Systemd::Timer::Job['codesearch-write-config'],
                File['/etc/hound-gitconfig'],
            ]
        }
    }
}
