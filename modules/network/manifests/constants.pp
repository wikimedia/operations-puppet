class network::constants {
    # Note this name is misleading.  Most of these are "external" networks,
    # but some subnets of the IPv6 space are not externally routed, even if
    # they're externally route-able (the ones used for private vlans).
    $module_path = get_module_path($module_name)
    $network_data = loadyaml("${module_path}/data/data.yaml")
    $all_network_subnets = $network_data['network::subnets']
    $external_networks = $network_data['network::external']
    $network_infra = $network_data['network::infrastructure']
    $mgmt_networks = $network_data['network::management']

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
    # $frack_networks will always contain just the fundraising networks
    $frack_networks = slice_network_constants('frack')

    $special_hosts = {
        'production' => {
            'deployment_hosts' => [
                    '10.64.32.16',                      # deploy1001.eqiad.wmnet
                    '2620:0:861:103:10:64:32:16',       # deploy1001.eqiad.wmnet
                    '10.192.32.24',                     # deploy2001.codfw.wmnet
                    '2620:0:860:103:10:192:32:24',      # deploy2001.codfw.wmnet
                ],
            },
        'labs' => {
            'deployment_hosts' => hiera('network::allow_deployment_from_ips', []), # lint:ignore:wmf_styleguide
            'cumin_real_masters' => [  # Where Cumin can be run
                    '208.80.154.158',               # labpuppetmaster1001.wikimedia.org
                    '2620:0:861:2:208:80:154:158',  # labpuppetmaster1001.wikimedia.org
                    '208.80.155.120',               # labpuppetmaster1002.wikimedia.org
                    '2620:0:861:4:208:80:155:120',  # labpuppetmaster1002.wikimedia.org
                ],
            }
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

    # Networks that Scap will be able to deploy to.
    # (Puppet does array concatenation
    # by declaring array of other arrays! (?!)
    # See: http://weblog.etherized.com/posts/175)
    $deployable_networks = [
        $mw_appserver_networks,
        $analytics_networks,
    ]
}
