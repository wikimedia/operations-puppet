# Class: role::labs::storage
#
# The role class for the storage (NFS) servers providing service
# to labs.
#
class role::labs::storage {

    include labs_storage::server

    labs_storage::snapshots { 'project':
        filesystem => '/srv/project',
    }

}
