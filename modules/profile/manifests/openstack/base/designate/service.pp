# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::designate::service(
    $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Array[OpenStack::ControlNode] $openstack_control_nodes = lookup('profile::openstack::base::openstack_control_nodes'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::base::puppetmaster_hostname'),
    $db_user = lookup('profile::openstack::base::designate::db_user'),
    $db_pass = lookup('profile::openstack::base::designate::db_pass'),
    $db_host = lookup('profile::openstack::base::designate::db_host'),
    $db_name = lookup('profile::openstack::base::designate::db_name'),
    String[1] $domain_id_internal_forward = lookup('profile::openstack::base::designate::domain_id_internal_forward'),
    String[1] $domain_id_internal_reverse_v4 = lookup('profile::openstack::base::designate::domain_id_internal_reverse_v4'),
    String[1] $domain_id_internal_reverse_v6 = lookup('profile::openstack::base::designate::domain_id_internal_reverse_v6'),
    String[1] $enabled_notification_handlers = lookup('profile::openstack::base::designate::enabled_notification_handlers'),
    String[1] $base_domain_name = lookup('profile::openstack::base::designate::base_domain_name'),
    $ldap_user_pass = lookup('profile::openstack::base::designate::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::base::pdns::api_key'),
    $db_admin_user = lookup('profile::openstack::base::designate::db_admin_user'),
    $db_admin_pass = lookup('profile::openstack::base::designate::db_admin_pass'),
    Array[Hash] $pdns_hosts = lookup('profile::openstack::base::pdns::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    $rabbit_user = lookup('profile::openstack::base::designate::rabbit_user'),
    $rabbit_pass = lookup('profile::openstack::base::designate::rabbit_pass'),
    $osm_host = lookup('profile::openstack::base::osm_host'),
    $region = lookup('profile::openstack::base::region'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    String $zookeeper_cluster_name = lookup('profile::openstack::base::designate::zookeeper_cluster_name'),
) {
    $own_cloud_private_fqdn = $openstack_control_nodes.filter |$entry| { $entry['host_fqdn'] == $facts['networking']['fqdn'] }[0]['cloud_private_fqdn']

    # we want a URL like
    #  zookeeper://cloudcontrol2005-dev.private.codfw.wikimedia.cloud:2181?hosts=cloudcontrol2006-dev.private.codfw.wikimedia.cloud:2181,cloudcontrol2010-dev.private.codfw.wikimedia.cloud:2181
    # order doesn't matter
    $first = "${designate_hosts[0]}:2181"
    $others = join(map(delete($designate_hosts, $designate_hosts[0])) | $hostfqdn| {"${hostfqdn}:2181"},',')
    $tooz_url = "zookeeper://${first}?hosts=${others}"

    class{'::openstack::designate::service':
        active                        => true,
        version                       => $version,
        designate_hosts               => $designate_hosts,
        keystone_fqdn                 => $keystone_fqdn,
        db_user                       => $db_user,
        db_pass                       => $db_pass,
        db_host                       => $db_host,
        db_name                       => $db_name,
        domain_id_internal_forward    => $domain_id_internal_forward,
        domain_id_internal_reverse_v4 => $domain_id_internal_reverse_v4,
        domain_id_internal_reverse_v6 => $domain_id_internal_reverse_v6,
        enabled_notification_handlers => $enabled_notification_handlers,
        base_domain_name              => $base_domain_name,
        puppetmaster_hostname         => $puppetmaster_hostname,
        memcached_nodes               => $openstack_control_nodes.map |$node| { $node['cloud_private_fqdn'] },
        ldap_user_pass                => $ldap_user_pass,
        pdns_api_key                  => $pdns_api_key,
        db_admin_user                 => $db_admin_user,
        db_admin_pass                 => $db_admin_pass,
        pdns_hosts                    => $pdns_hosts,
        rabbitmq_nodes                => $rabbitmq_nodes,
        rabbit_user                   => $rabbit_user,
        rabbit_pass                   => $rabbit_pass,
        region                        => $region,
        tooz_url                      => $tooz_url,
    }
    contain '::openstack::designate::service'

    firewall::service { 'designate-api-backend':
        proto  => 'tcp',
        port   => 9001,
        srange => $haproxy_nodes,
    }

    $raw_pdns_hosts = $pdns_hosts.map |$host| { $host['auth_ips'] }.flatten
    $pdns_hosts_private = $pdns_hosts.map |$host| { $host['private_fqdn'] }
    $mdns_clients = flatten([$designate_hosts, $raw_pdns_hosts, $pdns_hosts_private])
    # allow axfr traffic between mdns and pdns on the pdns hosts
    firewall::service { 'mdns-axfr-tcp':
        proto  => 'tcp',
        port   => 5354,
        srange => $mdns_clients,
    }

    firewall::service { 'mdns-axfr-udp':
        proto  => 'udp',
        port   => 5354,
        srange => $mdns_clients,
    }

    class{'::profile::zookeeper::monitoring::server':
        cluster_name => $zookeeper_cluster_name,
    }
    firewall::service { 'zookeeper':
        proto  => 'tcp',
        port   => [2181, 2182, 2183],
        srange => $designate_hosts,
    }
    class{'::profile::zookeeper::server':
        own_fqdn     => $own_cloud_private_fqdn,
        cluster_name => $zookeeper_cluster_name,
    }

    openstack::db::project_grants { 'designate':
        access_hosts => $designate_hosts + $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['designate'],
    }
}
