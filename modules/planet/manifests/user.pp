# adds a system user for a planet-venus install
class planet::user {

    generic::systemuser { 'planet':
        name   => 'planet',
        home   => '/var/lib/planet',
        groups => [ 'planet' ],
    }

}
