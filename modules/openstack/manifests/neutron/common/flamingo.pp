# SPDX-License-Identifier: Apache-2.0

class openstack::neutron::common::flamingo(
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Stdlib::Fqdn $keystone_fqdn,
    $db_pass,
    $db_user,
    $db_host,
    $region,
    $dhcp_domain,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    $log_agent_heartbeats,
    $agent_down_time,
    Stdlib::Port $bind_port,
    Array[String[1]] $type_drivers,
    Array[String[1]] $tenant_network_types,
    Array[String[1]] $mechanism_drivers,
    Integer                                              $default_mtu,
    Hash[String[1], OpenStack::Neutron::ProviderNetwork] $provider_networks,
    ) {

    class { "openstack::neutron::common::flamingo::${facts['os']['distro']['codename']}": }

    # Subtemplates of neutron.conf are going to want to know what
    #  version this is
    $version = inline_template("<%= @title.split(':')[-1] -%>")
    # And this, which is in hiera for every other service:
    $db_name = 'neutron'

    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    file { '/etc/neutron/neutron.conf':
            owner     => 'neutron',
            group     => 'neutron',
            mode      => '0660',
            show_diff => false,
            content   => template('openstack/flamingo/neutron/neutron.conf.erb'),
            require   => Package['neutron-common'];
    }

    file { '/etc/neutron/policy.yaml':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/flamingo/neutron/policy.yaml',
            require => Package['neutron-common'];
    }

    $provider_mtus = $provider_networks
        .map |String[1] $network, OpenStack::Neutron::ProviderNetwork $config| {
            if $config['mtu'] and $config['mtu'] != $default_mtu {
                "${network}:${config['mtu']}"
            } else {
                undef
            }
        }
        .filter |$it| { $it != undef }

    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0744',
        content => template('openstack/flamingo/neutron/plugins/ml2/ml2_conf.ini.erb'),
        require => Package['neutron-common'];
    }
}
