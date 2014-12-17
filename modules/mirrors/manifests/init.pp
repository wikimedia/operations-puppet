class mirrors {
    user { 'mirror':
        ensure     => present,
        gid        => 'mirror',
        home       => '/var/lib/mirror',
        managehome => true,
        system     => true,
    }

    group { 'mirror':
        ensure => present,
        name   => 'mirror',
        system => true,
    }
}
