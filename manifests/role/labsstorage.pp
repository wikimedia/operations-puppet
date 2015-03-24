# Class: role::labs::storage::{active,passive}
#
# The role class for the storage (NFS) servers providing service
# to labs.
#
class role::labs::storage::active {

    include labs_storage::server

    labs_storage::snapshots { 'project':
        filesystem => '/srv/project',
    }

}

class role::labs::storage::passive {

    include labs_storage::server

}
