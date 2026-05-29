# SPDX-License-Identifier: Apache-2.0

class profile::openstack::eqiad1::magnum(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Boolean $active = lookup('profile::openstack::eqiad1::magnum::active'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::eqiad1::openstack_control_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::eqiad1::rabbitmq_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::eqiad1::magnum::db_pass'),
    String $db_user = lookup('profile::openstack::eqiad1::magnum::db_host'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::eqiad1::magnum::db_host'),
    String $db_name = lookup('profile::openstack::eqiad1::magnum::db_name'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::magnum::api_bind_port'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::magnum::service_user_pass'),
    String $rabbit_pass = lookup('profile::openstack::eqiad1::magnum::rabbit_pass'),
    String $region = lookup('profile::openstack::eqiad1::region'),
    String $domain_admin_pass = lookup('profile::openstack::eqiad1::magnum::domain_admin_pass'),
    Stdlib::Fqdn $etcd_discovery_host = lookup('profile::openstack::eqiad1::magnum::etcd_discovery_host'),
    Array[Stdlib::Fqdn] $haproxy_nodes = lookup('profile::openstack::eqiad1::haproxy_nodes'),
    Boolean $heat_driver = lookup('profile::openstack::eqiad1::magnum::heat_driver'),
    Boolean $capi_driver = lookup('profile::openstack::eqiad1::magnum::capi_driver'),
) {
    class {'::profile::openstack::base::magnum':
        version                 => $version,
        active                  => $active,
        openstack_control_nodes => $openstack_control_nodes,
        rabbitmq_nodes          => $rabbitmq_nodes,
        keystone_fqdn           => $keystone_fqdn,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_host                 => $db_host,
        db_name                 => $db_name,
        etcd_discovery_host     => $etcd_discovery_host,
        api_bind_port           => $api_bind_port,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_pass             => $rabbit_pass,
        region                  => $region,
        domain_admin_pass       => $domain_admin_pass,
        haproxy_nodes           => $haproxy_nodes,
        heat_driver             => $heat_driver,
        capi_driver             => $capi_driver,
    }
    if $capi_driver {
        # this isn't set in a config file anyplace, apparently
        #  the cluster-api driver just looks for it in this pre-set
        #   location.
        file { '/var/lib/magnum/.kube/config':
            ensure    => 'present',
            mode      => '0600',
            owner     => 'magnum',
            group     => 'magnum',
            content   => secret('openstack/eqiad1/magnum/capiservicek3s.yaml'),
            show_diff => false,
        }
    }

    # Not really a part of magnum, for for convenience: install paws
    #  k8s access keys here for ssh access to worker nodes.
    file { '/etc/magnum/certs':
        ensure  => directory,
        owner   => 'magnum',
        group   => 'magnum',
        require => Class['::profile::openstack::base::magnum'],
        mode    => '0700',
    }
    file { '/etc/magnum/certs/paws_worker_key':
        ensure    => 'present',
        mode      => '0600',
        owner     => 'trove',
        group     => 'trove',
        require   => File['/etc/magnum/certs'],
        content   => secret('ssh/wmcs/paws/paws-magnum-vm-key-eqiad1'),
        show_diff => false,
    }
}
