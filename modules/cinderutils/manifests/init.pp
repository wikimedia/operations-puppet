class cinderutils {
    file { '/usr/sbin/prepare_cinder_volume':
        ensure => present,
        source => 'puppet:///modules/cinderutils/prepare_cinder_volume.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
    }
}
