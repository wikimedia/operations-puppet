class prometheus {
    file { '/etc/prometheus-nginx':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/srv/prometheus':
        ensure => directory,
    }
}
