# == class labstore
#
# This class configures the server as an NFS kernel server
# and sets the general configuration for that service, without
# actually exporting any filesystems
#

class labstore {
    
    require_package('nfs-kernel-server')

    # Labstores need to be able to scp from one server
    # to the other (in order to do backups)

    ssh::userkey { 'root-labstore':
        ensure => present,
        user   => 'root',
        skey   => 'labstore',
        source => 'puppet:///modules/labstore/id_labstore.pub',
    }

    file { '/root/.ssh/id_labstore':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///private/labstore/id_labstore',
    }

}

