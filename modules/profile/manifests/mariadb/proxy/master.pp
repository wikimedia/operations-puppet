# proxy in with 2 hosts, active-passive (with failover) scenario
class profile::mariadb::proxy::master (
    $primary_name   = hiera(::profile::mariadb::proxy::master::primary_name),
    $primary_addr   = hiera(::profile::mariadb::proxy::master::primary_addr),
    $secondary_name = hiera(::profile::mariadb::proxy::master::secondary_name),
    $secondary_addr = hiera(::profile::mariadb::proxy::master::seconady_addr),
    ) {
    # patch until all haproxies have been upgraded to 1.7
    if os_version('debian >= stretch') {
        $master_template = 'db-master-stretch.cfg'
    } else {
        $master_template = 'db-master.cfg'
    }

    file { '/etc/haproxy/conf.d/db-master.cfg':
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0440',
        content => template("profile/mariadb/proxy/${master_template}.erb"),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
    }
}
