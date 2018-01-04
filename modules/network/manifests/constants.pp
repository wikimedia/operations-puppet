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
                    '91.198.174.113',                   # bast3002.wikimedia.org
                    '2620:0:862:1:91:198:174:113',      # bast3002.wikimedia.org
                    '198.35.26.5',                      # bast4001.wikimedia.org
                    '2620:0:863:1:198:35:26:5',         # bast4001.wikimedia.org
                    '198.35.26.6',                      # bast4002.wikimedia.org
                    '2620:0:863:1:198:35:26:6',         # bast4002.wikimedia.org
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                ],
            'monitoring_hosts' => [
                    '208.80.153.74',                    # tegmen.wikimedia.org
                    '2620:0:860:3:208:80:153:74',       # tegmen.wikimedia.org
                    '208.80.155.119',                   # einsteinium.wikimedia.org
                    '2620:0:861:4:208:80:155:119',      # einsteinium.wikimedia.org
                    '208.80.154.82',                    # dbmonitor1001.wikimedia.org
                    '2620:0:861:3:208:80:154:82',       # dbmonitor1001.wikimedia.org
                    '208.80.153.52',                    # dbmonitor2001.wikimedia.org
                    '2620:0:860:2:208:80:153:52',       # dbmonitor2001.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.0.196',                      # tin.eqiad.wmnet
                    '2620:0:861:101:10:64:0:196',       # tin.eqiad.wmnet
                    '10.192.32.22',                     # naos.codfw.wmnet
                    '2620:0:860:103:10:192:32:22',      # naos.codfw.wmnet
                ],
            'maintenance_hosts' => [
                    '10.64.32.13',                      # terbium.eqiad.wmnet
                    '2620:0:861:103:10:64:32:13',       # terbium.eqiad.wmnet
                    '10.192.48.45',                     # wasat.codfw.wmnet
                    '2620:0:860:104:10:192:48:45',      # wasat.codfw.wmnet
                ],
            'puppet_frontends' => [
                    '10.64.16.73',                # puppetmaster1001.eqiad.wmnet
                    '2620:0:861:102:10:64:16:73', # puppetmaster1001.eqiad.wmnet
                    '10.192.0.27',                # puppetmaster2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:27', # puppetmaster2001.codfw.wmnet
                ],
            'cumin_masters' => [
                    '10.64.32.20',                 # neodymium.eqiad.wmnet
                    '2620:0:861:103:10:64:32:20',  # neodymium.eqiad.wmnet
                    '10.192.0.140',                # sarin.codfw.wmnet
                    '2620:0:860:101:10:192:0:140', # sarin.codfw.wmnet
                ],
            'mysql_root_clients' => [
                    # ipv6 interfaces are not yet allowed due to mysql grants
                    # do not put dns names or hostnames here, only ipv4
                    '10.64.0.15',                  # db1011.eqiad.wmnet
                    '10.64.32.20',                 # neodymium.eqiad.wmnet
                    '10.192.0.140',                # sarin.codfw.wmnet
                ],
            'kafka_brokers_main' => [
                    '10.64.0.11',                         # kafka1001.eqiad.wmnet
                    '2620:0:861:101:1618:77ff:fe33:5242', # kafka1001.eqiad.wmnet
                    '10.64.16.41',                        # kafka1002.eqiad.wmnet
                    '2620:0:861:102:1618:77ff:fe33:4a4e', # kafka1002.eqiad.wmnet
                    '10.64.32.127',                       # kafka1003.eqiad.wmnet
                    '2620:0:861:103:1618:77ff:fe33:4ad2', # kafka1003.eqiad.wmnet
                    '10.192.0.139',                       # kafka2001.codfw.wmnet
                    '2620:0:860:101:1618:77ff:fe39:6f37', # kafka2001.codfw.wmnet
                    '10.192.16.169',                      # kafka2002.codfw.wmnet
                    '2620:0:860:102:1618:77ff:fe33:500d', # kafka2002.codfw.wmnet
                    '10.192.32.150',                      # kafka2003.codfw.wmnet
                    '2620:0:860:103:1a66:daff:fe7f:23f0', # kafka2003.codfw.wmnet
                ],
            'kafka_brokers_analytics' => [
                    '10.64.5.12',                  # kafka1012.eqiad.wmnet
                    '2620:0:861:104:10:64:5:12',   # kafka1012.eqiad.wmnet
                    '10.64.5.13',                  # kafka1013.eqiad.wmnet
                    '2620:0:861:104:10:64:5:13',   # kafka1013.eqiad.wmnet
                    '10.64.36.114',                # kafka1014.eqiad.wmnet
                    '2620:0:861:106:10:64:36:114', # kafka1014.eqiad.wmnet
                    '10.64.53.12',                 # kafka1020.eqiad.wmnet
                    '2620:0:861:108:10:64:53:12',  # kafka1020.eqiad.wmnet
                    '10.64.36.122',                # kafka1022.eqiad.wmnet
                    '2620:0:861:106:10:64:36:122', # kafka1022.eqiad.wmnet
                    '10.64.5.14',                  # kafka1023.eqiad.wmnet
                    '2620:0:861:104:10:64:5:14',   # kafka1023.eqiad.wmnet
                ],
            'kafka_brokers_jumbo' => [
                    '10.64.0.175',                        # kafka-jumbo1001.eqiad.wmnet
                    '2620:0:861:101:1a66:daff:fefc:d530', # kafka-jumbo1001.eqiad.wmnet
                    '10.64.0.176',                        # kafka-jumbo1002.eqiad.wmnet
                    '2620:0:861:101:1a66:daff:fefc:c8f8', # kafka-jumbo1002.eqiad.wmnet
                    '10.64.16.99',                        # kafka-jumbo1003.eqiad.wmnet
                    '2620:0:861:102:1a66:daff:fefc:ccbc', # kafka-jumbo1003.eqiad.wmnet
                    '10.64.32.159',                       # kafka-jumbo1004.eqiad.wmnet
                    '2620:0:861:103:1a66:daff:fefb:5e68', # kafka-jumbo1004.eqiad.wmnet
                    '10.64.32.160',                       # kafka-jumbo1005.eqiad.wmnet
                    '2620:0:861:103:1a66:daff:fefc:d59c', # kafka-jumbo1005.eqiad.wmnet
                    '10.64.48.117',                       # kafka-jumbo1006.eqiad.wmnet
                    '2620:0:861:107:1a66:daff:fefc:d27c', # kafka-jumbo1006.eqiad.wmnet
                ],
            'zookeeper_hosts_main' => [
                    '10.64.0.18',                         # conf1001.eqiad.wmnet
                    '2620:0:861:101:d6ae:52ff:fe73:60e6', # conf1001.eqiad.wmnet
                    '10.64.32.180',                       # conf1002.eqiad.wmnet
                    '2620:0:861:103:d6ae:52ff:fe7c:c9ec', # conf1002.eqiad.wmnet
                    '10.64.48.111',                       # conf1003.eqiad.wmnet
                    '2620:0:861:107:d6ae:52ff:fe7c:b5ed', # conf1003.eqiad.wmnet
                    '10.192.0.143',                       # conf2001.codfw.wmnet
                    '2620:0:860:101:1618:77ff:fe5e:a72c', # conf2001.codfw.wmnet
                    '10.192.32.141',                      # conf2002.codfw.wmnet
                    '2620:0:860:103:1618:77ff:fe5e:a175', # conf2002.codfw.wmnet
                    '10.192.48.52',                       # conf2003.codfw.wmnet
                    '2620:0:860:104:1618:77ff:fe5e:a4c2', # conf2003.codfw.wmnet
                ],
            'hadoop_masters' => [
                    '10.64.36.118',                       # analytics1001.eqiad.wmnet
                    '2620:0:861:106:f21f:afff:fee8:af06', # analytics1001.eqiad.wmnet
                    '10.64.53.21',                        # analytics1002.eqiad.wmnet
                    '2620:0:861:108:f21f:afff:fee8:bc3f', # analytics1002.eqiad.wmnet
                ],
            'druid_analytics_hosts' => [
                    '10.64.5.101',                        # druid1001.eqiad.wmnet
                    '2620:0:861:104:1e98:ecff:fe29:e298', # druid1001.eqiad.wmnet
                    '10.64.36.102',                       # druid1002.eqiad.wmnet
                    '2620:0:861:106:1602:ecff:fe06:8bec', # druid1002.eqiad.wmnet
                    '10.64.53.103',                       # druid1003.eqiad.wmnet
                    '2620:0:861:108:1e98:ecff:fe29:e278', # druid1003.eqiad.wmnet
                ],
            'druid_public_hosts' => [
                    '10.64.0.35',                         # druid1004.eqiad.wmnet
                    '2620:0:861:101:1a66:daff:feac:87a1', # druid1004.eqiad.wmnet
                    '10.64.16.172',                       # druid1005.eqiad.wmnet
                    '2620:0:861:102:1a66:daff:feae:36fb', # druid1005.eqiad.wmnet
                    '10.64.48.171',                       # druid1006.eqiad.wmnet
                    '2620:0:861:107:1a66:daff:feac:75cd', # druid1006.eqiad.wmnet
                ],
            'cache_misc' => [
                    '10.64.32.97',                        # cp1045.eqiad.wmnet
                    '2620:0:861:103:10:64:32:97',         # cp1045.eqiad.wmnet
                    '10.64.32.103',                       # cp1051.eqiad.wmnet
                    '2620:0:861:103:10:64:32:103',        # cp1051.eqiad.wmnet
                    '10.64.0.95',                         # cp1058.eqiad.wmnet
                    '2620:0:861:101:10:64:0:95',          # cp1058.eqiad.wmnet
                    '10.64.0.98',                         # cp1061.eqiad.wmnet
                    '2620:0:861:101:10:64:0:98',          # cp1061.eqiad.wmnet
                    '10.192.0.127',                       # cp2006.codfw.wmnet
                    '2620:0:860:101:10:192:0:127',        # cp2006.codfw.wmnet
                    '10.192.16.138',                      # cp2012.codfw.wmnet
                    '2620:0:860:102:10:192:16:138',       # cp2012.codfw.wmnet
                    '10.192.32.117',                      # cp2018.codfw.wmnet
                    '2620:0:860:103:10:192:32:117',       # cp2018.codfw.wmnet
                    '10.192.48.29',                       # cp2025.codfw.wmnet
                    '2620:0:860:104:10:192:48:29',        # cp2025.codfw.wmnet
                    '10.20.0.107',                        # cp3007.esams.wmnet
                    '2620:0:862:102:10:20:0:107',         # cp3007.esams.wmnet
                    '10.20.0.108',                        # cp3008.esams.wmnet
                    '2620:0:862:102:10:20:0:108',         # cp3008.esams.wmnet
                    '10.20.0.109',                        # cp3009.esams.wmnet
                    '2620:0:862:102:10:20:0:109',         # cp3009.esams.wmnet
                    '10.20.0.110',                        # cp3010.esams.wmnet
                    '2620:0:862:102:10:20:0:110',         # cp3010.esams.wmnet
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
            'maintenance_hosts' => [
                    '',  # deployment-terbium.deployment-prep.eqiad.wmflabs ?
                    '',  # deployment-wasat.deployment-prep.eqiad.wmflabs ?
                ],
            'cumin_masters' => [  # As seen by labs instances
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                ],
            'cumin_real_masters' => [  # Where Cumin can be run
                    '208.80.154.158',               # labpuppetmaster1001.wikimedia.org
                    '2620:0:861:2:208:80:154:158',  # labpuppetmaster1001.wikimedia.org
                    '208.80.155.120',               # labpuppetmaster1002.wikimedia.org
                    '2620:0:861:4:208:80:155:120',  # labpuppetmaster1002.wikimedia.org
                ],
            'cache_misc' => [ # So that roles with CACHE_MISC in ferm rules can be used in labs
                    '10.68.21.68', # novaproxy-01.project-proxy.eqiad.wmflabs
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
