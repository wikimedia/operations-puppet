# vim: set ts=4 et sw=4:

class role::mathoid{
    system::role { 'role::mathoid':
        description => 'mathoid server',
    }

    include ::mathoid
}
