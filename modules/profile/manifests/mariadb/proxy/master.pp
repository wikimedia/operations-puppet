# proxy in with 2 hosts, active-passive (with failover) scenario
class profile::mariadb::proxy::master (
    $primary_name   = hiera('profile::mariadb::proxy::master::primary_name'),
    $primary_addr   = hiera('profile::mariadb::proxy::master::primary_addr'),
    $secondary_name = hiera('profile::mariadb::proxy::master::secondary_name'),
    $secondary_addr = hiera('profile::mariadb::proxy::master::secondary_addr'),
    ) {

    # this template is for stretch/HA1.7, may not work on earlier/later versions
    $master_template = 'db-master.cfg.erb'

    file { '/etc/haproxy/conf.d/db-master.cfg':
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0440',
        content => template("profile/mariadb/proxy/${master_template}"),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
    }
}
