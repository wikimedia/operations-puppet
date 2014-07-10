class zuul::user {

    group { 'zuul':
        ensure => present,
        name   => 'zuul',
        system => true,
    }

    user { 'zuul':
        home       => '/var/lib/zuul',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

}
