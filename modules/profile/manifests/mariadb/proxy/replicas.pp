# load balancing between several replica dbs
class profile::mariadb::proxy::replicas(
    $servers = hiera('profile::mariadb::proxy::replicas::servers'),
    ) {

    # patch until all haproxies have been upgraded to 1.7
    if os_version('debian >= stretch') {
        $replicas_template = 'db-replicas-stretch.cfg.erb'
    } else {
        $replicas_template = 'db-replicas.cfg.erb'
    }
    file { '/etc/haproxy/conf.d/db-replicas.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("profile/mariadb/proxy/${replicas_template}"),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
    }
}
