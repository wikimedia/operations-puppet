# SPDX-License-Identifier: Apache-2.0
class network::constants {
    $module_path = get_module_path($module_name)
    $network_data = loadyaml("${module_path}/data/data.yaml")
    $all_network_subnets = $network_data['network::subnets']

    # Note this name (external_networks) is misleading.  Most of these are "external" networks,
    # but some subnets of the IPv6 space are not externally routed, even if
    # they're externally route-able (the ones used for private vlans).
    $external_networks = $network_data['network::external']

    $customers_networks = $network_data['network::customers']

    $network_infra = $network_data['network::infrastructure']

    $mgmt_networks_bydc = $network_data['network::management']
    $mgmt_networks = $mgmt_networks_bydc.values.flatten

    # $network_realm is to map $::realm == 'labs' to 'cloud' for this module.
    # I hope it will eventually go away when $::realm will be 'cloud'. (Famous last words.)
    $network_realm = $::realm ? {
        'labs'  => 'cloud',
        default => $::realm,
    }

    # Per realm aggregate networks
    $aggregate_networks = flatten($network_data['network::aggregate_networks'][$network_realm])

    # $domain_networks is a set of all networks belonging to a domain.
    # a domain is a realm currently, but the notion is more generic than that on
    # purpose.
    # TODO: Figure out a way this can be per-project networks in ClouD VPS
    $domain_networks = slice_network_constants($network_realm)
    # $production_networks will always contain just the production networks
    $production_networks = slice_network_constants('production')
    # $labs_networks will always contain just the Cloud VPS networks
    $labs_networks = slice_network_constants('cloud')
    # $cloud_networks_public contains basically general egress NAT and floating IP addresses
    $cloud_networks_public = slice_network_constants('cloud', { 'sphere' => 'public' })

    # $cloud_private_networks is the per site list of cloud-private IPs assigned to
    # dual-realm servers.
    $cloud_private_networks = {
        'eqiad' => slice_network_constants(
            'cloud',
            {
                sphere      => 'private',
                description => 'cloud-private',
                site        => 'eqiad',
            }
        ),
        'codfw' => slice_network_constants(
            'cloud',
            {
                sphere      => 'private',
                description => 'cloud-private',
                site        => 'codfw',
            }
        )
    }
    $all_cloud_private_networks = $cloud_private_networks.values.flatten()

    # $cloud_instance_networks is the list of Cloud VPS internal instance networks
    # per site.
    $cloud_instance_networks = {
        'eqiad' => slice_network_constants(
            'cloud',
            {
                sphere      => 'private',
                description => 'cloud-instances',
                site        => 'eqiad',
            }
        ),
        'codfw' => slice_network_constants(
            'cloud',
            {
                sphere      => 'private',
                description => 'cloud-instances',
                site        => 'codfw',
            }
        )
    }

    # $frack_networks will always contain just the fundraising networks
    $frack_networks = slice_network_constants('frack')

    # cloud nova hosts ranges per region
    $cloud_nova_hosts_ranges = {
        'eqiad1-r' => slice_network_constants('production', {
            site        => $::site,
            description => 'cloud-hosts',
        }),
        'codfw1dev-r' => slice_network_constants('production', {
            site        => 'codfw',
            description => 'cloud-hosts',
        }),
    }

    # Networks hosting MediaWiki application servers
    # These are:
    #  - public hosts in eqiad/codfw
    #  - all private networks in eqiad/codfw
    if $network_realm == 'production' {
        $mw_appserver_networks_public = flatten([
            slice_network_constants('production', {
                'site'        => 'eqiad',
                'sphere'      => 'public',
                'description' => '-[abcd]-',
                }),
            slice_network_constants('production', {
                'site'   => 'codfw',
                'sphere' => 'public',
                'description' => '-[abcd]-',
                }),
            ])
        $mw_appserver_networks_private = flatten([
            slice_network_constants('production', {
                'site'        => 'eqiad',
                'sphere'      => 'private',
                'description' => 'private\d?-[abcdef]\d?-',
                }),
            slice_network_constants('production', {
                'site'        => 'codfw',
                'sphere'      => 'private',
                'description' => 'private\d?-[abcdef]\d?-',
                }),
            slice_network_constants('production', {
                'sphere'      => 'private',
                'description' => '-kubepods-',
                }),
            ])
        $mw_appserver_networks = concat($mw_appserver_networks_private, $mw_appserver_networks_public)
    } elsif $network_realm == 'cloud' {
        # rely on security groups to restrict this
        $mw_appserver_networks = flatten([
            slice_network_constants('cloud'),
            '127.0.0.1'])
        $mw_appserver_networks_private = flatten([
            slice_network_constants('cloud'),
            '127.0.0.1'])
    } else {
        fail("unknown realm '${network_realm}'")
    }

    # Analytics subnets
    $analytics_networks = slice_network_constants('production', { 'description' => 'analytics'})

    # Kubernetes pods subnets. We could revisit in the future if we makes sense to have
    # this at a global level or not (effie).
    $services_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'eqiad',
            'sphere'      => 'private',
            'description' => 'services-kubepods',
            }),
        slice_network_constants('production', {
            'site'        => 'codfw',
            'sphere'      => 'private',
            'description' => 'services-kubepods',
            }),
        ])
    $staging_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'eqiad',
            'sphere'      => 'private',
            'description' => 'staging-kubepods',
            }),
        slice_network_constants('production', {
            'site'        => 'codfw',
            'sphere'      => 'private',
            'description' => 'staging-kubepods',
            }),
        ])
    $mlserve_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'eqiad',
            'sphere'      => 'private',
            'description' => 'mlserve-kubepods',
            }),
        slice_network_constants('production', {
            'site'        => 'codfw',
            'sphere'      => 'private',
            'description' => 'mlserve-kubepods',
            }),
        ])
    $mlstage_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'codfw',
            'sphere'      => 'private',
            'description' => 'mlstage-kubepods',
            }),
        ])
    $aux_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'eqiad',
            'sphere'      => 'private',
            'description' => 'aux-kubepods',
            }),
        ])
    $dse_kubepods_networks = flatten([
        slice_network_constants('production', {
            'site'        => 'eqiad',
            'sphere'      => 'private',
            'description' => 'dse-kubepods',
            }),
        ])


    # Networks that Scap will be able to deploy to.
    # (Puppet does array concatenation
    # by declaring array of other arrays! (?!)
    # See: http://weblog.etherized.com/posts/175)
    $deployable_networks = [
        $mw_appserver_networks,
        $analytics_networks,
    ]
}
