class profile::openstack::codfw1dev::galera::monitoring(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Integer             $nodecount             = lookup('profile::openstack::codfw1dev::galera::node_count'),
    Stdlib::Port        $port                  = lookup('profile::openstack::codfw1dev::galera::listen_port'),
    String              $test_username         = lookup('profile::openstack::codfw1dev::galera::test_username'),
    String              $test_password         = lookup('profile::openstack::codfw1dev::galera::test_password'),
){
    $openstack_controllers.each |$db_hostname| {
        # Bypass haproxy and check the backend mysqld port directly. We want to notice
        #  degraded service even if the haproxy'd front end is holding up.
        @monitoring::service { "wmcs-galera-${db_hostname}":
            host          => $db_hostname,
            description   => 'WMCS Galera Cluster',
            check_command => "check_galera_nodes!${nodecount}!${port}!${test_username}!${test_password}",
            critical      => true,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
        }
    }
}
