# SPDX-License-Identifier: Apache-2.0
# Really Awful Notorious CIsco config Differ
class rancid (
    Stdlib::Fqdn $active_server,
){

    package { 'rancid':
        ensure => present,
    }

    group { 'rancid':
        ensure => present,
        name   => 'rancid',
        system => true,
    }

    user { 'rancid':
        shell      => '/bin/sh',
        gid        => 'rancid',
        managehome => true,
        system     => true,
        home       => '/var/lib/rancid',
    }

    ::keyholder::agent { 'rancid':
        require        => Group['rancid'],
        trusted_groups => ['rancid'],
    }

    file { '/etc/rancid/rancid.conf':
        require => Package['rancid'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('rancid/rancid.conf.erb'),
    }

    file { '/var/lib/rancid/bin/oglogin':
        require => Package['rancid'],
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/rancid/bin/oglogin',
    }

    file { '/var/lib/rancid/bin/ograncid':
        require => Package['rancid'],
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/rancid/bin/ograncid',
    }

    file { '/var/lib/rancid/bin/ssh-serial-console-wrapper':
        require => Package['rancid'],
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/rancid/bin/ssh-serial-console-wrapper',
    }

    file { '/var/lib/rancid/core':
        require => [ Package['rancid'], User['rancid'] ],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0774',
        recurse => remote,
        source  => 'puppet:///modules/rancid/core',
    }

    file { '/var/lib/rancid/core/configs':
        ensure  => 'directory',
        require => [ Package['rancid'], User['rancid'] ],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0774',
    }

    file { '/var/lib/rancid/.cloginrc':
        require => Package['rancid'],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0440',
        content => template('rancid/cloginrc.erb'),
    }

    file { '/var/lib/rancid/.gitconfig':
        require => Package['rancid'],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0440',
        content => template('rancid/gitconfig.erb'),
    }

    file { '/var/lib/rancid/.ssh':
        ensure  => 'directory',
        require => [ Package['openssh-client', 'rancid'], User['rancid'] ],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0700',
    }

    file_line { 'opengear_script':
      path => '/etc/rancid/rancid.types.base',
      line => 'opengear;script;ograncid',
    }

    file_line { 'opengear_login':
      path => '/etc/rancid/rancid.types.base',
      line => 'opengear;login;oglogin',
    }

    if $active_server == $::fqdn {
        $job_ensure = 'present'
    } else {
        $job_ensure = 'absent'
    }

    systemd::timer::job { 'rancid-differ':
        ensure             => $job_ensure,
        user               => 'rancid',
        description        => 'run rancid-run',
        environment        => { 'SSH_AUTH_SOCK' => '/run/keyholder/proxy.sock' },
        command            => '/usr/lib/rancid/bin/rancid-run',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    systemd::timer::job { 'rancid-clean-logs':
        ensure             => $job_ensure,
        user               => 'rancid',
        description        => 'clean rancid logs',
        command            => '/usr/bin/find /var/log/rancid -type f -mtime +2 -exec rm {} \;',
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 23:50:0'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    file { '/var/log/rancid':
        owner => 'rancid',
        group => 'rancid',
        mode  => '0750',
    }
}
