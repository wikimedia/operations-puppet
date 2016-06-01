class labstore::fileserver::primary {

    requires_os('Debian >= jessie')

    include labstore

    require_package('python3-paramiko')
    require_package('python3-pymysql')

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
