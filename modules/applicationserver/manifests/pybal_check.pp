class applicationserver::pybal_check {
    group { 'pybal-check':
        ensure => present,
    }

    user { 'pybal-check':
        ensure     => present,
        gid        => 'pybal-check',
        shell      => '/bin/sh',
        home       => '/var/lib/pybal-check',
        system     => true,
        managehome => true,
    }

    file { '/var/lib/pybal-check/.ssh':
        ensure  => directory,
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0550',
    }

    file { '/var/lib/pybal-check/.ssh/authorized_keys':
        owner   => 'pybal-check',
        group   => 'pybal-check',
        mode    => '0440',
        source  => 'puppet:///modules/applicationserver/pybal_key',
    }
}
