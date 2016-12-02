class role::labs::nfs::secondary_backup::base {

    system::role { 'role::labs::nfs::secondary_backup':
        description => 'NFS shares secondary backup',
    }

    include labstore::backup_keys

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }

    file {'/srv/backup':
        ensure  => 'directory',
    }

}
