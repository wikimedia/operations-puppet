class network::constants {
    # Note this name is misleading.  Most of these are "external" networks,
    # but some subnets of the IPv6 space are not externally routed, even if
    # they're externally route-able (the ones used for private vlans).
    $external_networks = [
        '91.198.174.0/24',
        '208.80.152.0/22',
        '2620:0:860::/46',
        '198.35.26.0/23',
        '185.15.56.0/22',
        '2a02:ec80::/32',
    ]

    # are you really sure you want to use this? maybe what you really
    # the trusted/production networks. See $production_networks for this.
    $all_networks = flatten([$external_networks, '10.0.0.0/8'])
    $all_networks_lo = flatten([$all_networks, '127.0.0.0/8', '::1/128'])

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
            'bastion_hosts' => [
                    '208.80.154.149',                   # bast1001.wikimedia.org
                    '2620:0:861:2:208:80:154:149',      # bast1001.wikimedia.org
                    '208.80.153.5',                     # bast2001.wikimedia.org
                    '2620:0:860:1:208:80:153:5',        # bast2001.wikimedia.org
                    '91.198.174.112',                   # bast3001.wikimedia.org
                    '2620:0:862:1:91:198:174:112',      # bast3001.wikimedia.org
                    '198.35.26.5',                      # bast4001.wikimedia.org
                    '2620:0:863:1:198:35:26:5',         # bast4001.wikimedia.org
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                ],
            'monitoring_hosts' => [
                    '208.80.154.14',                    # neon.wikimedia.org
                    '2620:0:861:1:208:80:154:14',       # neon.wikimedia.org
                    '208.80.153.74',                    # tegmen.wikimedia.org
                    '2620:0:860:3:208:80:153:74/64',    # tegmen.wikimedia.org
                    '208.80.155.119',                   # einsteinium.wikimedia.org
                    '2620:0:860:3:208:80:155:119/64',   # einsteinium.wikimedia.org
                    '208.80.154.53',                    # uranium.wikimedia.org (ganglia, gmetad needs it)
                    '2620:0:861:1:208:80:154:53',       # uranium.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.0.196',                      # tin.eqiad.wmnet
                    '2620:0:861:101:10:64:0:196',       # tin.eqiad.wmnet
                    '10.192.16.132',                    # mira.codfw.wmnet
                    '2620:0:860:102:10:192:16:132',     # mira.codfw.wmnet
                ],
            'puppet_frontends' => [
                    '10.64.16.160',               # palladium.eqiad.wmnet
                    '2620:0:861:102:10:64:16:16', # palladium.eqiad.wmnet
                    '10.64.16.73',                # puppetmaster1001.eqiad.wmnet
                    '2620:0:861:102:10:64:16:73', # puppetmaster1001.eqiad.wmnet
                    '10.192.0.27',                # puppetmaster2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:27', # puppetmaster2001.codfw.wmnet
                ],
            },
        'labtest' => {
            'bastion_hosts' => [
                    '208.80.154.149',                   # bast1001.wikimedia.org
                    '2620:0:861:2:208:80:154:149',      # bast1001.wikimedia.org
                    '208.80.153.5',                     # bast2001.wikimedia.org
                    '2620:0:860:1:208:80:153:5',        # bast2001.wikimedia.org
                    '91.198.174.112',                   # bast3001.wikimedia.org
                    '2620:0:862:1:91:198:174:112',      # bast3001.wikimedia.org
                    '198.35.26.5',                      # bast4001.wikimedia.org
                    '2620:0:863:1:198:35:26:5',         # bast4001.wikimedia.org
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                ],
            'monitoring_hosts' => [
                    '208.80.154.14',                    # neon.wikimedia.org
                    '2620:0:861:1:208:80:154:14',       # neon.wikimedia.org
                    '2620:0:861:1:7a2b:cbff:fe08:a42f', # neon.wikimedia.org SLAAC
                    '208.80.154.53',                    # uranium.wikimedia.org (ganglia, gmetad needs it)
                    '2620:0:861:1:208:80:154:53',       # uranium.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.0.196',                      # tin.eqiad.wmnet
                    '2620:0:861:101:10:64:0:196',       # tin.eqiad.wmnet
                    '10.192.16.132',                    # mira.codfw.wmnet
                    '2620:0:860:102:10:192:16:132',     # mira.codfw.wmnet
                ],
            },
        'labs' => {
            'bastion_hosts' => concat([
                    '10.68.17.232', # bastion-01.eqiad.wmflabs
                    '10.68.18.65',  # bastion-02.eqiad.wmflabs
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                ], hiera('network::allow_ssh_from_ips', [])), # Allow labs projects to setup their own ssh origination points
            'monitoring_hosts' => [
                    '10.68.16.210', # shinken-01.eqiad.wmflabs
                ],
            'deployment_hosts' => [
                    '10.68.21.205',  # deployment-tin.deployment-prep.eqiad.wmflabs
                    '10.68.20.135',  # deployment-mira.deployment-prep.eqiad.wmflabs
                ],
            }
    }

    $all_network_subnets = hiera('network::subnets')

    # Networks hosting MediaWiki application servers
    # These are:
    #  - public hosts in eqiad/codfw
    #  - nobelium in eqiad labs support
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
    } elsif $::realm == 'labtest' {
        # This just a placeholder... .erb doesn't like this to be empty.
        $mw_appserver_networks = ['208.80.152.0/22']
    }

    # Analytics subnets
    $analytics_networks = slice_network_constants('production', { 'description' => 'analytics'})

    # Networks that trebuchet/git-deploy
    # will be able to deploy to.
    # (Puppet does array concatenation
    # by declaring array of other arrays! (?!)
    # See: http://weblog.etherized.com/posts/175)
    $deployable_networks = [
        $mw_appserver_networks,
        $analytics_networks,
    ]
}
