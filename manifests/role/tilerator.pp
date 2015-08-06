# Role class for tilerator
class role::tilerator {

    system::role { 'role::tilerator':
        description => 'A vector map tile generation service',
    }

    include ::tilerator
}

