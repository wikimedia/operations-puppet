# database read-only load balancing proxy
class role::mariadb::proxy::slaves(
    $shard,
    $servers,
    ) {

    class { 'role::mariadb::proxy':
        shard => $shard,
    }

    file { '/etc/haproxy/conf.d/db-slaves.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('role/haproxy/db-slaves.cfg.erb'),
    }
}
