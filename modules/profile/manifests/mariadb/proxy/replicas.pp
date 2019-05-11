# load balancing between several replica dbs
class profile::mariadb::proxy::replicas(
    $servers = hiera('profile::mariadb::proxy::replicas::servers'),
    ) {

    # This template is for stretch/HA1.7, may not work on earlier/later versions
    $replicas_template = 'db-replicas.cfg.erb'

    file { '/etc/haproxy/conf.d/db-replicas.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("profile/mariadb/proxy/${replicas_template}"),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
    }
}
