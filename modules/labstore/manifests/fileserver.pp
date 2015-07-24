# == class labstore::fileserver
#
# This configures a server for serving NFS filesystems to Labs
# instances.  Applying this classes suffices to make a server
# capable of serving this function, but neither activates nor
# enables it to do so by itself (as this requires manual
# intervention at this time because of the shared storage).
class labstore::fileserver {

    include ::labstore

    file { '/usr/local/sbin/replica-addusers.pl':
        source => 'puppet:///modules/labstore/replica-addusers.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    file { '/etc/init/replica-addusers.conf':
        source  => 'puppet:///modules/labstore/replica-addusers.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/local/sbin/replica-addusers.pl'],
    }

    file { '/etc/replication-rsync.conf':
        source => 'puppet:///modules/labstore/replication-rsync.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/usr/local/sbin/storage-replicate':
        source  => 'puppet:///modules/labstore/storage-replicate',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/replication-rsync.conf'],
    }

    labstore::fileserver::replicate { 'tools':
        src_path  => '/srv/project/tools',
        dest_path => '/srv/eqiad/tools',
        dest_host => 'labstore2001.codfw.wmnet',
    }

    labstore::fileserver::replicate { 'others':
        src_path  => '/srv/others',
        dest_path => '/srv/eqiad/others',
        dest_host => 'labstore2001.codfw.wmnet',
    }

    labstore::fileserver::replicate { 'maps':
        src_path  => '/srv/project/maps',
        dest_path => '/srv/eqiad/maps',
        dest_host => 'labstore2001.codfw.wmnet',
    }

    # There is no service {} stanza on purpose -- this service
    # must *only* be started by a manual operation because it must
    # run exactly once on whichever NFS server is the current
    # active one.

    file { '/usr/local/sbin/start-nfs':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        source  => 'puppet:///modules/labstore/start-nfs',
    }

    include ::labstore::fileserver::exports
}
