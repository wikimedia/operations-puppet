class labstore::bdsync {

    package { 'bdsync':
        ensure => present,
        before => File['/usr/local/sbin/block_sync'],
    }

    file { '/usr/local/sbin/block_sync':
        source => 'puppet:///modules/labstore/block_sync.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
