# user for a planet-venus install
class planet::user {

  systemuser { 'planet':
    name   => 'planet',
    home   => '/var/lib/planet',
    groups => [ 'planet' ],
  }

}
