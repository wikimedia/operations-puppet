class zuul::user {

    group { 'zuul':
        ensure => present,
        gid    => 923,
        name   => 'zuul',
        system => true,
    }

    user { 'zuul':
        uid        => 923,
        home       => '/var/lib/zuul',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

}
