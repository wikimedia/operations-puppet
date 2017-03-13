# db master failover with a proxy
class role::mariadb::proxy::master(
    $shard,
    $primary_name,
    $primary_addr,
    $secondary_name,
    $secondary_addr,
    ) {

    include role::mariadb::ferm

    class { 'role::mariadb::proxy':
        shard => $shard,
    }

    file { '/etc/haproxy/conf.d/db-master.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('role/haproxy/db-master.cfg.erb'),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
    }
}

