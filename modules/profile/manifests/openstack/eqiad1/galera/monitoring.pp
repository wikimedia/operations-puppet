class profile::openstack::eqiad1::galera::monitoring(
    Integer             $nodecount             = lookup('profile::openstack::eqiad1::galera::node_count'),
    Stdlib::Port        $port                  = lookup('profile::openstack::eqiad1::galera::listen_port'),
    String              $test_username         = lookup('profile::openstack::eqiad1::galera::test_username'),
    String              $test_password         = lookup('profile::openstack::eqiad1::galera::test_password'),
){
    # Bypass haproxy and check the backend mysqld port directly. We want to notice
    #  degraded service even if the haproxy'd front end is holding up.
    monitoring::service { 'galera_cluster':
        description   => 'WMCS Galera Cluster',
        check_command => "check_galera_node!${nodecount}!${port}!${test_username}!${test_password}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        contact_group => 'wmcs-team',
    }

    monitoring::service { 'galera_db':
        description   => 'WMCS Galera Database',
        check_command => "check_galera_db!${port}!${test_username}!${test_password}",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        contact_group => 'wmcs-team',
    }
    # We should know if galera fails over
    nrpe::monitor_service { 'haproxy_failover':
        description   => 'haproxy service failover',
        nrpe_command  => '/usr/local/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/HAProxy',
        contact_group => 'wmcs-team-email,wmcs-bots',
    }
}
