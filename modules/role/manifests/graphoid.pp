# vim: set ts=4 et sw=4:
#
# filtertags: labs-project-deployment-prep labs-project-maps-team
class role::graphoid {

    system::role { 'role::graphoid':
        description => 'node.js service converting graph definitions into PNG'
    }

    include ::graphoid
}
