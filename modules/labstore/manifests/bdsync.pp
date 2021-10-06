class labstore::bdsync {
    ensure_packages(['python3-dateutil', 'bdsync'])

    file { '/usr/local/sbin/block_sync':
        source => 'puppet:///modules/labstore/block_sync.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
