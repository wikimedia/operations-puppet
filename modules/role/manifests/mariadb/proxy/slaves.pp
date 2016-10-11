class role::mariadb::proxy::slaves(
    $shard,
    $servers,
    ) {

    class { 'role::mariadb::proxy::slaves':
        shard => $shard,
    }

    file { '/etc/haproxy/conf.d/db-slaves.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mariadb/haproxy-slaves.cfg.erb'),
    }
}

