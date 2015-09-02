# == class labstore::fileserver
#
# This configures a server for serving NFS filesystems to Labs
# instances.  Applying this classes suffices to make a server
# capable of serving this function, but neither activates nor
# enables it to do so by itself (as this requires manual
# intervention at this time because of the shared storage).
class labstore::fileserver {

    include ::labstore

    # Set to true only for the labstore that is currently
    # actively serving files
    $is_active = (hiera('active_labstore_host') == $::hostname)

    require_package('lvm2')
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
        source  => 'puppet:///modules/labstore/cleanup-snapshots',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
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

        # Monitor instance NFS availability, only on the active labstore and make it paging
        monitoring::service { 'nfs-on-labs-instances':
            description   => 'NFS read/writeable on labs instances',
            check_command => 'check_http_url_at_address_for_string!tools-checker.wmflabs.org!/nfs/home!OK',
            critical      => true,
        }
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
    include ::labstore::account_services
}
