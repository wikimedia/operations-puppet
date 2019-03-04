class profile::wmcs::nfs::bdsync {
    require_package(['python3-dateutil', 'bdsync'])

    file { '/usr/local/sbin/block_sync':
        source => 'puppet:///modules/profile/wmcs/nfs/block_sync.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
