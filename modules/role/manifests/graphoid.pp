# vim: set ts=4 et sw=4:
class role::graphoid {

    system::role { 'role::graphoid':
        description => 'node.js service converting graph definitions into PNG'
    }

    include ::graphoid
}
