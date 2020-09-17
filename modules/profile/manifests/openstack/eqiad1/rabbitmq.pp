class profile::openstack::eqiad1::rabbitmq(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    $monitor_user = lookup('profile::openstack::eqiad1::rabbit_monitor_user'),
    $monitor_password = lookup('profile::openstack::eqiad1::rabbit_monitor_pass'),
    $cleanup_password = lookup('profile::openstack::eqiad1::rabbit_cleanup_pass'),
    $file_handles = lookup('profile::openstack::eqiad1::rabbit_file_handles'),
    $labs_hosts_range = lookup('profile::openstack::eqiad1::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::eqiad1::labs_hosts_range_v6'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    $nova_rabbit_password = lookup('profile::openstack::eqiad1::nova::rabbit_pass'),
    $neutron_rabbit_user = lookup('profile::openstack::base::neutron::rabbit_user'),
    $neutron_rabbit_password = lookup('profile::openstack::eqiad1::neutron::rabbit_pass'),
    $rabbit_erlang_cookie = lookup('profile::openstack::eqiad1::rabbit_erlang_cookie'),
){

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::rabbitmq':
        openstack_controllers => $openstack_controllers,
        monitor_user          => $monitor_user,
        monitor_password      => $monitor_password,
        cleanup_password      => $cleanup_password,
        file_handles          => $file_handles,
        labs_hosts_range      => $labs_hosts_range,
        labs_hosts_range_v6   => $labs_hosts_range_v6,
        designate_hosts       => $designate_hosts,
        nova_rabbit_password  => $nova_rabbit_password,
        rabbit_erlang_cookie  => $rabbit_erlang_cookie,
    }
    contain '::profile::openstack::base::rabbitmq'

    # move to base when appropriate along with lookups above
    class {'::openstack::neutron::rabbit':
        username => $neutron_rabbit_user,
        password => $neutron_rabbit_password,
    }
    contain '::openstack::neutron::rabbit'
}
