class labstore::bdsync {
    require_package(['python3-dateutil', 'bdsync'])

    file { '/usr/local/sbin/block_sync':
        source => 'puppet:///modules/labstore/block_sync.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
