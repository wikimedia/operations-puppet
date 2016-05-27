class network::constants {

    # Dummy resource to allow RSpec to work with hiera lookups. Without it RSpec
    # will not load hiera settings and unrelated tests about functions in this
    # module will fail. Any resource would be, but this class has none
    notify { 'dummy': message => '' }

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

    $production_networks = slice_network_constants('production')

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
            'bastion_hosts' => [
                    '10.68.17.232', # bastion-01.eqiad.wmflabs
                    '10.68.18.65',  # bastion-02.eqiad.wmflabs
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                ],
            'monitoring_hosts' => [
                    '10.68.16.210', # shinken-01.eqiad.wmflabs
                ],
            'deployment_hosts' => [
                    '10.68.17.240',  # deployment-tin.deployment-prep.eqiad.wmflabs
                    '10.68.17.215',  # mira.deployment-prep.eqiad.wmflabs
                ],
            }
    }

    $all_network_subnets = hiera('network::subnets')

    # Networks hosting MediaWiki application servers
    if $::realm == 'production' {
        # TODO: Revisit this structure in the future
        $mw_appserver_networks =
            [
                '208.80.152.0/22',    # external
                '2620:0:860::/46',    # all external previous was for silver
                '10.64.37.14/32',     # nobelium, temporary mw install to copy over es indices
                '2620:0:861:119:f21f:afff:fee8:b1fb/64', # same as ^
                $all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-a-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-b-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-c-eqiad']['ipv6'],
                $all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv4'],
                $all_network_subnets['production']['eqiad']['private']['private1-d-eqiad']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-a-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-b-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-c-codfw']['ipv6'],
                $all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv4'],
                $all_network_subnets['production']['codfw']['private']['private1-d-codfw']['ipv6'],
            ]
    } elsif $::realm == 'labs' {
        # rely on security groups in labs to restrict this
        $mw_appserver_networks = ['10.0.0.0/8', '127.0.0.1']
    } elsif $::realm == 'labtest' {
        # This just a placeholder... .erb doesn't like this to be empty.
        $mw_appserver_networks = ['208.80.152.0/22']
    }

    # Analytics subnets
    $analytics_networks = [
        $all_network_subnets['production']['eqiad']['private']['analytics1-a-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-a-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-b-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-b-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-c-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-c-eqiad']['ipv6'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-d-eqiad']['ipv4'],
        $all_network_subnets['production']['eqiad']['private']['analytics1-d-eqiad']['ipv6'],
    ]

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
