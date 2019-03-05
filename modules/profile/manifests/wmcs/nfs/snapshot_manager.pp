class profile::wmcs::nfs::snapshot_manager {

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/wmcs/nfs/server/snapshot-manager.py',
    }

}
