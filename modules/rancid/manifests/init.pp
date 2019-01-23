# Really Awful Notorious CIsco config Differ
class rancid (
    Stdlib::Fqdn $active_server
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
        source  => 'puppet:///modules/rancid/rancid.conf',
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

    file { '/var/lib/rancid/.cloginrc':
        require => Package['rancid'],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0440',
        content => template('rancid/cloginrc.erb'),
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
        $cron_ensure = 'present'
    } else {
        $cron_ensure = 'absent'
    }

    cron { 'rancid_differ':
        ensure  => $cron_ensure,
        command => 'SSH_AUTH_SOCK=/run/keyholder/proxy.sock /usr/lib/rancid/bin/rancid-run',
        user    => 'rancid',
        minute  => '1',
    }

    cron { 'rancid_clean_logs':
        ensure  => $cron_ensure,
        command => '/usr/bin/find /var/log/rancid -type f -mtime +2 -exec rm {} \;',
        user    => 'rancid',
        minute  => '50',
        hour    => '23',
    }

    file { '/var/log/rancid':
        owner => 'rancid',
        group => 'rancid',
        mode  => '0750',
    }
}
