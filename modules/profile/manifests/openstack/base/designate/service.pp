class profile::openstack::base::designate::service(
    $version = hiera('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    $keystone_host = hiera('profile::openstack::base::keystone_host'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $db_user = hiera('profile::openstack::base::designate::db_user'),
    $db_pass = hiera('profile::openstack::base::designate::db_pass'),
    $db_host = hiera('profile::openstack::base::designate::db_host'),
    $db_name = hiera('profile::openstack::base::designate::db_name'),
    $domain_id_internal_forward_legacy = hiera('profile::openstack::base::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_forward = hiera('profile::openstack::base::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = hiera('profile::openstack::base::designate::domain_id_internal_reverse'),
    $ldap_user_pass = hiera('profile::openstack::base::ldap_user_pass'),
    $pdns_db_user = hiera('profile::openstack::base::designate::pdns_db_user'),
    $pdns_db_pass = hiera('profile::openstack::base::designate::pdns_db_pass'),
    $pdns_db_name = hiera('profile::openstack::base::designate::pdns_db_name'),
    $pdns_api_key = lookup('profile::openstack::base::pdns::api_key'),
    $db_admin_user = hiera('profile::openstack::base::designate::db_admin_user'),
    $db_admin_pass = hiera('profile::openstack::base::designate::db_admin_pass'),
    $primary_pdns = hiera('profile::openstack::base::designate::host'),
    $secondary_pdns = hiera('profile::openstack::base::designate::host_secondary'),
    $rabbit_user = hiera('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = hiera('profile::openstack::base::nova::rabbit_pass'),
    $keystone_public_port = hiera('profile::openstack::base::keystone::public_port'),
    $keystone_auth_port = hiera('profile::openstack::base::keystone::auth_port'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    $region = hiera('profile::openstack::base::region'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    $puppet_git_repo_name = lookup('profile::openstack::base::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::base::horizon::puppet_git_repo_user'),
    Integer $mcrouter_port = lookup('profile::openstack::base::designate::mcrouter_port'),
    ) {

    $primary_pdns_ip = ipresolve($primary_pdns,4)
    $secondary_pdns_ip = ipresolve($secondary_pdns,4)

    class{'::openstack::designate::service':
        active                            => true,
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_host                     => $keystone_host,
        db_user                           => $db_user,
        db_pass                           => $db_pass,
        db_host                           => $db_host,
        db_name                           => $db_name,
        domain_id_internal_forward        => $domain_id_internal_forward,
        domain_id_internal_forward_legacy => $domain_id_internal_forward_legacy,
        domain_id_internal_reverse        => $domain_id_internal_reverse,
        puppetmaster_hostname             => $puppetmaster_hostname,
        openstack_controllers             => $openstack_controllers,
        ldap_user_pass                    => $ldap_user_pass,
        pdns_db_user                      => $pdns_db_user,
        pdns_db_pass                      => $pdns_db_pass,
        pdns_db_name                      => $pdns_db_name,
        pdns_api_key                      => $pdns_api_key,
        db_admin_user                     => $db_admin_user,
        db_admin_pass                     => $db_admin_pass,
        primary_pdns_ip                   => $primary_pdns_ip,
        secondary_pdns_ip                 => $secondary_pdns_ip,
        rabbit_user                       => $rabbit_user,
        rabbit_pass                       => $rabbit_pass,
        keystone_public_port              => $keystone_public_port,
        keystone_auth_port                => $keystone_auth_port,
        region                            => $region,
        puppet_git_repo_name              => $puppet_git_repo_name,
        puppet_git_repo_user              => $puppet_git_repo_user,
    }
    contain '::openstack::designate::service'

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ip6s = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $prometheus_ferm_srange = "@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA)"
    # Open designate API to WMCS web UIs and the commandline on control servers, also prometheus
    ferm::rule { 'designate-api':
        rule => "saddr (@resolve(${osm_host}) ${labweb_ip6s} @resolve(${keystone_host}) @resolve(${keystone_host}, AAAA)
                       ${labweb_ips} @resolve((${join($openstack_controllers,' ')}))
                       @resolve((${join($openstack_controllers,' ')}), AAAA)
                       ${prometheus_ferm_srange}
                 ) proto tcp dport (9001) ACCEPT;",
    }

    # Allow labs instances to hit the designate api.
    #
    # This is not as permissive as it looks; The wmfkeystoneauth
    #  plugin (via the password whitelist) only allows 'novaobserver'
    #  to authenticate from within labs, and the novaobserver is
    #  limited by the designate policy.json to read-only queries.
    include network::constants
    $labs_networks = join($network::constants::labs_networks, ' ')
    ferm::rule { 'designate-api-for-labs':
        rule => "saddr (${labs_networks}) proto tcp dport (9001) ACCEPT;",
    }

    # allow axfr traffic between mdns and pdns on the pdns hosts
    ferm::rule { 'mdns-axfr':
        rule => "saddr (@resolve((${join($designate_hosts,' ')}))
                        @resolve((${join($designate_hosts,' ')}), AAAA))
                 proto tcp dport (5354) ACCEPT;",
    }

    ferm::rule { 'mdns-axfr-udp':
        rule => "saddr (@resolve((${join($designate_hosts,' ')}))
                        @resolve((${join($designate_hosts,' ')}), AAAA))
                 proto udp dport (5354) ACCEPT;",
    }

    # Replicated cache set including all designate hosts.
    # This will be used for tooz coordination by designate.
    #
    # The route config here is copy/pasted from
    #  https://github.com/facebook/mcrouter/wiki/Replicated-pools-setup
    #
    # The cross-region bits don't actually matter but the parent class expects them.
    class { '::mcrouter':
        region                   => $::site,
        cluster                  => 'designate',
        cross_region_timeout_ms  => 250,
        cross_cluster_timeout_ms => 1000,
        pools                    => {
            'designate' => {
                servers => $designate_hosts.map |$designatehost| { sprintf('%s:11000:ascii:plain',ipresolve($designatehost,4)) }
            },
        },
        routes                   => [
            aliases              => [ "/${::site}/designate/" ],
            route                => {
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

    class { '::memcached':
    }
    class { '::profile::prometheus::memcached_exporter': }

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
        srange  => "(@resolve((${join($designate_hosts,' ')}))
                    @resolve((${join($designate_hosts,' ')}), AAAA))",
    }

    ferm::service { 'memcached_for_mcrouter':
        desc    => 'Allow connections to memcached',
        proto   => 'tcp',
        notrack => true,
        port    => 11000,
        srange  => "(@resolve((${join($designate_hosts,' ')}))
                    @resolve((${join($designate_hosts,' ')}), AAAA))",
    }
}
