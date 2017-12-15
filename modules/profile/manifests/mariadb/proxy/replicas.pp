# load balancing between several replica dbs
class profile::mariadb::proxy::replicas(
    $servers = hiera('::profile::mariadb::proxy::replicas::servers'),
    ) {

    file { '/etc/haproxy/conf.d/db-replicas.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/mariadb/proxy/db-replicas.cfg.erb'),
    }
}
