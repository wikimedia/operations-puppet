# Really Awful Notorious CIsco config Differ
class rancid {

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
    }

    include passwords::rancid

    file { '/etc/rancid/rancid.conf':
        require => Package['rancid'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/rancid/rancid.conf',
    }

    file { '/var/lib/rancid/core':
        require => [ Package['rancid'], User['rancid'] ],
        owner   => 'rancid',
        group   => 'rancid',
        mode    => '0770',
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

    file { '/etc/cron.d/rancid':
        require => File['/var/lib/rancid/core'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/rancid/rancid.cron',
    }

    file { '/var/log/rancid':
        owner => 'rancid',
        group => 'rancid',
        mode  => '0750',
    }
}
