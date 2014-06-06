# adds a system user for a planet-venus install
class planet::user {

    user { 'planet':
        home       => '/var/lib/planet',
        groups     => [ 'planet' ],
        managehome => true,
        system     => true,
    }

}
