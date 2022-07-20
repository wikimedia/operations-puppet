class profile::openstack::base::designate::service(
    $version = lookup('profile::openstack::base::version'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    $puppetmaster_hostname = lookup('profile::openstack::base::puppetmaster_hostname'),
    $db_user = lookup('profile::openstack::base::designate::db_user'),
    $db_pass = lookup('profile::openstack::base::designate::db_pass'),
    $db_host = lookup('profile::openstack::base::designate::db_host'),
    $db_name = lookup('profile::openstack::base::designate::db_name'),
    $domain_id_internal_forward_legacy = lookup('profile::openstack::base::designate::domain_id_internal_forward_legacy'),
    $domain_id_internal_forward = lookup('profile::openstack::base::designate::domain_id_internal_forward'),
    $domain_id_internal_reverse = lookup('profile::openstack::base::designate::domain_id_internal_reverse'),
    $ldap_user_pass = lookup('profile::openstack::base::ldap_user_pass'),
    $pdns_api_key = lookup('profile::openstack::base::pdns::api_key'),
    $db_admin_user = lookup('profile::openstack::base::designate::db_admin_user'),
    $db_admin_pass = lookup('profile::openstack::base::designate::db_admin_pass'),
    Array[Stdlib::Fqdn] $pdns_hosts = lookup('profile::openstack::base::designate::hosts'),
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    $rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    $rabbit_pass = lookup('profile::openstack::base::nova::rabbit_pass'),
    $keystone_public_port = lookup('profile::openstack::base::keystone::public_port'),
    $keystone_auth_port = lookup('profile::openstack::base::keystone::auth_port'),
    $osm_host = lookup('profile::openstack::base::osm_host'),
    $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    $region = lookup('profile::openstack::base::region'),
    $puppet_git_repo_name = lookup('profile::openstack::base::horizon::puppet_git_repo_name'),
    $puppet_git_repo_user = lookup('profile::openstack::base::horizon::puppet_git_repo_user'),
    Integer $mcrouter_port = lookup('profile::openstack::base::designate::mcrouter_port'),
    ) {

    class{'::openstack::designate::service':
        active                            => true,
        version                           => $version,
        designate_hosts                   => $designate_hosts,
        keystone_api_fqdn                 => $keystone_api_fqdn,
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
        pdns_api_key                      => $pdns_api_key,
        db_admin_user                     => $db_admin_user,
        db_admin_pass                     => $db_admin_pass,
        pdns_hosts                        => $pdns_hosts,
        rabbitmq_nodes                    => $rabbitmq_nodes,
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
    # Open designate API to WMCS web UIs and the commandline on control servers
    ferm::rule { 'designate-api':
        rule => "saddr (@resolve((${join($openstack_controllers,' ')}))
                        @resolve((${join($openstack_controllers,' ')}), AAAA)
                 ) proto tcp dport (9001) ACCEPT;",
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
        region      => $::site,
        cluster     => 'designate',
        pools       => {
            'designate' => {
                servers => $designate_hosts.map |$designatehost| { sprintf('%s:11000:ascii:plain',ipresolve($designatehost,4)) }
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

    class { '::memcached':
        # TODO: the following were implicit defaults from
        # MW settings, need to be reviewed.
        growth_factor => 1.05,
        min_slab_size => 5,
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

    openstack::db::project_grants { 'designate':
        access_hosts => $designate_hosts + $openstack_controllers,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
