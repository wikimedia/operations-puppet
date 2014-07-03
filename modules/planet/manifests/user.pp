# adds a system user for a planet-venus install
class planet::user {

    group { 'planet':
        ensure => present,
        name   => 'planet',
        system => true,
    }

    user { 'planet':
        home       => '/var/lib/planet',
        groups     => [ 'planet' ],
        managehome => true,
        system     => true,
    }

}
