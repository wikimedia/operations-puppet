class salt::orchestration() {
    file { '/usr/local/sbin/wmf-auto-reimage':
        ensure => present,
        source => 'puppet:///modules/salt/wmf_auto_reimage.py',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }
}
