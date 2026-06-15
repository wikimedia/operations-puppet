# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::api::service(
    $version = lookup('profile::openstack::base::version'),
    String $region = lookup('profile::openstack::base::region'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::base::nova::osapi_compute_listen_port'),
    Stdlib::Port $metadata_bind_port = lookup('profile::openstack::base::nova::metadata_listen_port'),
    String       $dhcp_domain               = lookup('profile::openstack::base::nova::dhcp_domain',
                                                      {default_value => 'example.com'}),
    Integer      $compute_workers = lookup('profile::openstack::base::nova::compute_workers'),
    Stdlib::Fqdn $keystone_fqdn        = lookup('profile::openstack::base::keystone_api_fqdn'),
    String $observer_password          = lookup('profile::openstack::base::observer_password'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Array[Stdlib::IP::Address] $cloud_cumin_bastions = lookup('profile::openstack::base::cloud_cumin_bastions'),
) {
    class {'::openstack::nova::api::service':
        version              => $version,
        active               => true,
        api_bind_port        => $api_bind_port,
        metadata_bind_port   => $metadata_bind_port,
        dhcp_domain          => $dhcp_domain,
        compute_workers      => $compute_workers,
        keystone_fqdn        => $keystone_fqdn,
        observer_password    => $observer_password,
        region               => $region,
        cloud_cumin_bastions => $cloud_cumin_bastions,
    }
    contain '::openstack::nova::api::service'

    firewall::service { 'nova-api-backend':
        proto  => 'tcp',
        port   => $api_bind_port,
        srange => $haproxy_nodes,
    }

    firewall::service { 'nova-metadata-backend':
        proto  => 'tcp',
        port   => $metadata_bind_port,
        srange => $haproxy_nodes,
    }
}
