class labstore::fileserver::primary {

    requires_os('Debian >= jessie')

    # Set to true only for the labstore that is currently
    # actively serving files
    $is_active = (hiera('active_labstore_host') == $::hostname)

    include labstore
    include labstore::fileserver::exports
    include labstore::account_services

    require_package('python3-paramiko')
    require_package('python3-pymysql')

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
        mode    => '0544',
        require => File['/etc/replication-rsync.conf'],
    }

    file { '/usr/local/sbin/cleanup-snapshots':
        source => 'puppet:///modules/labstore/cleanup-snapshots',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }

    if $is_active {
        # These should only run on the active host

        # They are staggered by one hour to avoid contention during the write-barriers caused
        # by the creation of snapshots during the backup process.
        labstore::fileserver::replicate { 'tools':
            src_path  => '/srv/project/tools',
            dest_path => '/srv/eqiad/tools',
            dest_host => 'labstore2001.codfw.wmnet',
            calendar  => '02:00',
        }

        labstore::fileserver::replicate { 'others':
            src_path  => '/srv/others',
            dest_path => '/srv/eqiad/others',
            dest_host => 'labstore2001.codfw.wmnet',
            calendar  => '03:00',
        }

        labstore::fileserver::replicate { 'maps':
            src_path  => '/srv/project/maps',
            dest_path => '/srv/eqiad/maps',
            dest_host => 'labstore2001.codfw.wmnet',
            calendar  => '04:00',
        }

        labstore::fileserver::cleanup_snapshots { 'labstore':
            keep_free => '6',
        }
    }

    # There is no service {} stanza on purpose -- this service
    # must *only* be started by a manual operation because it must
    # run exactly once on whichever NFS server is the current
    # active one.

    file { '/usr/local/sbin/start-nfs':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/labstore/start-nfs',
    }
}
