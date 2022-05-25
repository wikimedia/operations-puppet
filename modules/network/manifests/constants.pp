class network::constants {
    $module_path = get_module_path($module_name)
    $network_data = loadyaml("${module_path}/data/data.yaml")
    $all_network_subnets = $network_data['network::subnets']

    # Note this name (external_networks) is misleading.  Most of these are "external" networks,
    # but some subnets of the IPv6 space are not externally routed, even if
    # they're externally route-able (the ones used for private vlans).
    $external_networks = $network_data['network::external']

    $network_infra = $network_data['network::infrastructure']

    $mgmt_networks_bydc = $network_data['network::management']
    $mgmt_networks = $mgmt_networks_bydc.values.flatten

    # Per realm aggregate networks
    $aggregate_networks = flatten($network_data['network::aggregate_networks'][$::realm])

    # $domain_networks is a set of all networks belonging to a domain.
    # a domain is a realm currently, but the notion is more generic than that on
    # purpose.
    # TODO: Figure out a way this can be per-project networks in labs
    $domain_networks = slice_network_constants($::realm)
    # $production_networks will always contain just the production networks
    $production_networks = slice_network_constants('production')
    # $labs_networks will always contain just the labs networks
    $labs_networks = slice_network_constants('labs')
    # $cloud_networks_public contains basically general egress NAT and floating IP addresses
    $cloud_networks_public = slice_network_constants('labs', { 'sphere' => 'public' })
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
    if $::realm == 'production' {
        $mw_appserver_networks = flatten([
            slice_network_constants('production', {
                'site'   => 'eqiad',
                'sphere' => 'public',
                }),
            slice_network_constants('production', {
                'site'   => 'codfw',
                'sphere' => 'public',
                }),
            slice_network_constants('production', {
                'site'        => 'eqiad',
                'sphere'      => 'private',
                'description' => 'private',
                }),
            slice_network_constants('production', {
                'site'        => 'codfw',
                'sphere'      => 'private',
                'description' => 'private',
                }),
            slice_network_constants('production', {
                'site'        => 'eqiad',
                'sphere'      => 'private',
                'description' => 'labs-support',
                }),
            ])
    } elsif $::realm == 'labs' {
        # rely on security groups in labs to restrict this
        $mw_appserver_networks = flatten([
            slice_network_constants('labs'),
            '127.0.0.1'])
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

    # Networks that Scap will be able to deploy to.
    # (Puppet does array concatenation
    # by declaring array of other arrays! (?!)
    # See: http://weblog.etherized.com/posts/175)
    $deployable_networks = [
        $mw_appserver_networks,
        $analytics_networks,
    ]
}
