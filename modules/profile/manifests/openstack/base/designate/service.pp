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
    Integer $mcrouter_port = lookup('profile::openstack::base::designate::mcrouter_port'),
    Array[Stdlib::Host] $haproxy_nodes = lookup('profile::openstack::base::haproxy_nodes'),
    Enum['zookeeper', 'mcrouter'] $tooz_backend = lookup('profile::openstack::base::designate::tooz_backend'),
    String $zookeeper_cluster_name = lookup('profile::openstack::base::designate::zookeeper_cluster_name'),
) {
    $own_cloud_private_fqdn = $openstack_control_nodes.filter |$entry| { $entry['host_fqdn'] == $facts['networking']['fqdn'] }[0]['cloud_private_fqdn']

    if $tooz_backend == 'zookeeper' {
        # we want a URL like 
        #  zookeeper://cloudcontrol2005-dev.private.codfw.wikimedia.cloud:2181?hosts=cloudcontrol2006-dev.private.codfw.wikimedia.cloud:2181,cloudcontrol2010-dev.private.codfw.wikimedia.cloud:2181
        # order doesn't matter
        $first = "${designate_hosts[0]}:2181"
        $others = join(map(delete($designate_hosts, $designate_hosts[0])) | $hostfqdn| {"${hostfqdn}:2181"},',')
        $tooz_url = "zookeeper://${first}?hosts=${others}"
    } else {
        $tooz_url  = 'memcached://localhost:11213'
    }

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


    if ( $tooz_backend ==  'mcrouter') {
        # Replicated cache set including all designate hosts.
        # This will be used for tooz coordination by designate.
        #
        # The route config here is copy/pasted from
        #  https://github.com/facebook/mcrouter/wiki/Replicated-pools-setup
        #
        # The cross-region bits don't actually matter but the parent class expects them.
        class { '::mcrouter':
            region      => $::site,
            cluster     => 'designate',
            pools       => {
                'designate' => {
                    servers => $designate_hosts.map |$designatehost| { sprintf('%s:11211:ascii:plain',ipresolve($designatehost,4)) }
                },
            },
            routes      => [
                aliases => [ "/${::site}/designate/" ],
                route   => {
                    type               => 'OperationSelectorRoute',
                    default_policy     => 'PoolRoute|designate',
                    operation_policies => {
                        add    => 'AllSyncRoute|Pool|designate',
                        delete => 'AllSyncRoute|Pool|designate',
                        get    => 'LatestRoute|Pool|designate',
                        set    => 'AllSyncRoute|Pool|designate'
                    }
                }
            ]
        }


        ferm::rule { 'skip_mcrouter_designate_conntrack_out':
            desc  => 'Skip outgoing connection tracking for mcrouter',
            table => 'raw',
            chain => 'OUTPUT',
            rule  => "proto tcp sport (${mcrouter_port}) NOTRACK;",
        }

        ferm::rule { 'skip_mcrouter_designate_conntrack_in':
            desc  => 'Skip incoming connection tracking for mcrouter',
            table => 'raw',
            chain => 'PREROUTING',
            rule  => "proto tcp dport (${mcrouter_port}) NOTRACK;",
        }

        ferm::service { 'mcrouter':
            desc    => 'Allow connections to mcrouter',
            proto   => 'tcp',
            notrack => true,
            port    => $mcrouter_port,
            srange  => $designate_hosts,
        }
    } elsif $tooz_backend == 'zookeeper' {
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
    }

    openstack::db::project_grants { 'designate':
        access_hosts => $designate_hosts + $haproxy_nodes,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
        require      => Package['designate'],
    }

}
