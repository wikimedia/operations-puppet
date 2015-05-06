# Service user to handle the post-merge hook on master
class puppetmaster::gitpuppet {
    user { 'gitpuppet':
        ensure     => present,
        shell      => '/bin/sh',
        home       => '/home/gitpuppet',
        managehome => true,
        system     => true,
    }
    file { '/home/gitpuppet/.ssh':
        ensure  => directory,
        owner   => 'gitpuppet',
        group   => 'gitpuppet',
        mode    => '0700',
        require => User['gitpuppet'],
    }
    file { '/home/gitpuppet/.ssh/id_rsa':
            ensure  => present,
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0400',
            source  => 'puppet:///private/ssh/gitpuppet/gitpuppet.key',
            require => File['/home/gitpuppet/.ssh'],
    }
    file { '/home/gitpuppet/.ssh/gitpuppet-private-repo':
            ensure  => present,
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0400',
            source  => 'puppet:///private/ssh/gitpuppet/gitpuppet-private.key',
            require => File['/home/gitpuppet/.ssh'],
    }
    ssh::userkey { 'gitpuppet':
        ensure => present,
        source => 'puppet:///modules/puppetmaster/git/gitpuppet_authorized_keys',
    }
}
