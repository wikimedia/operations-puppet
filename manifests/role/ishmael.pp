# manifests/role/ishmael.pp

class role::ishmael {

    system::role { 'role::ishmael': description => 'ishmael server' }

    include ishmael

}
