# = Class: codesearch
#
# This class sets up the basics needed for MediaWiki code search
# hosted at codesearch.wmflabs.org
#
class codesearch(
    Optional[Stdlib::Unixpath] $base_dir = undefined,
    Hash[String, Integer] $ports = undefined,
){
    $hound_dir  = "${base_dir}/hound"
    $clone_dir  = "${base_dir}/codesearch"
    $puppet_dir = "${base_dir}/puppet"

    apt::package_from_component { 'thirdparty-kubeadm-k8s':
        component => 'thirdparty/kubeadm-k8s',
        packages  => ['docker-ce'],
    }

    require_package([
        'gunicorn3',
        'python3-flask',
        'python3-requests',
        'python3-yaml',
    ])

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

    git::clone {'operations/puppet':
        ensure    => latest,
        directory => $puppet_dir,
        branch    => 'production',
        require   => User['codesearch'],
        owner     => 'codesearch',
        group     => 'codesearch',
    }

    # Alias production to master for puppet
    exec { 'puppet alias origin/master':
        command => '/usr/bin/git symbolic-ref refs/remotes/origin/master refs/remotes/origin/production',
        cwd     => $puppet_dir,
        user    => 'codesearch',
        creates => "${puppet_dir}/.git/refs/remotes/origin/master",
        require => Git::Clone['operations/puppet'],
    }

    exec { 'puppet alias master':
        command => '/usr/bin/git symbolic-ref refs/heads/master refs/heads/production',
        cwd     => $puppet_dir,
        user    => 'codesearch',
        creates => "${puppet_dir}/.git/refs/heads/master",
        require => Git::Clone['operations/puppet'],
    }

    systemd::timer::job { 'codesearch-write-config':
        description => 'Generate hound configuration files',
        command     => "${clone_dir}/write_config.py",
        user        => 'codesearch',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00',  # Every day at midnight
        },
        require     => [
            Git::Clone['labs/codesearch'],
            User['codesearch'],
        ],
    }

    systemd::service { 'hound_proxy':
        ensure  => present,
        content => template('codesearch/initscripts/hound_proxy.service.erb'),
        restart => true,
        require => [
            Git::Clone['labs/codesearch'],
            Package['gunicorn3'],
            File['/etc/codesearch_ports.json'],
        ]
    }

    file { '/etc/codesearch_ports.json':
        ensure  => present,
        content => ordered_json($ports),
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
                Git::Clone['operations/puppet'],
                Systemd::Timer::Job['codesearch-write-config'],
            ]
        }
    }
}
