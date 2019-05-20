class profile::openstack::eqiad1::rabbitmq(
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::eqiad1::nova_controller_standby'),
    $nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $monitor_user = hiera('profile::openstack::eqiad1::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::eqiad1::rabbit_monitor_pass'),
    $cleanup_password = hiera('profile::openstack::eqiad1::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::eqiad1::rabbit_file_handles'),
    $labs_hosts_range = hiera('profile::openstack::eqiad1::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::eqiad1::labs_hosts_range_v6'),
    $nova_api_host = hiera('profile::openstack::eqiad1::nova_api_host'),
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $designate_host_standby = hiera('profile::openstack::eqiad1::designate_host_standby'),
    $nova_rabbit_password = hiera('profile::openstack::eqiad1::nova::rabbit_pass'),
    $neutron_rabbit_user = hiera('profile::openstack::base::neutron::rabbit_user'),
    $neutron_rabbit_password = hiera('profile::openstack::eqiad1::neutron::rabbit_pass'),
    $rabbit_erlang_cookie = hiera('profile::openstack::eqiad1::rabbit_erlang_cookie'),
){

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::rabbitmq':
        nova_controller_standby => $nova_controller_standby,
        nova_controller         => $nova_controller,
        monitor_user            => $monitor_user,
        monitor_password        => $monitor_password,
        cleanup_password        => $cleanup_password,
        file_handles            => $file_handles,
        labs_hosts_range        => $labs_hosts_range,
        labs_hosts_range_v6     => $labs_hosts_range_v6,
        nova_api_host           => $nova_api_host,
        designate_host          => $designate_host,
        designate_host_standby  => $designate_host_standby,
        nova_rabbit_password    => $nova_rabbit_password,
        rabbit_erlang_cookie    => $rabbit_erlang_cookie,
    }
    contain '::profile::openstack::base::rabbitmq'

    # move to base when appropriate along with lookups above
    class {'::openstack::neutron::rabbit':
        username => $neutron_rabbit_user,
        password => $neutron_rabbit_password,
    }
    contain '::openstack::neutron::rabbit'
}
