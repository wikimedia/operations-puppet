# radosgw packages and service.  The config is combined with glance/ceph config
#  and defined in profile::openstack::base::rbd_cloudcontrol
class profile::openstack::base::radosgw(
    String              $version       = lookup('profile::openstack::base::version'),
    Stdlib::Port        $api_bind_port = lookup('profile::openstack::base::radosgw::api_bind_port'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
) {
    require profile::cloudceph::auth::deploy

    class { '::openstack::radosgw::service':
        version => $version,
    }

    include ::network::constants
    $prod_networks = join($network::constants::production_networks, ' ')
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::service { 'radosgw-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => "@resolve((${haproxy_nodes.join(' ')}))",
    }
}
