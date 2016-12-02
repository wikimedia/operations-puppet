class labstore::bdsync {

    package { 'bdsync':
        ensure => present,
        before => File['/usr/local/sbin/block_sync'],
    }

    file { '/usr/local/sbin/snapshot-manager':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/labstore/snapshot-manager.py',
    }

    file { '/usr/local/sbin/block_sync':
        source => 'puppet:///modules/labstore/block_sync.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
