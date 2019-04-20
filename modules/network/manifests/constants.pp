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
            'monitoring_hosts' => [
                    '208.80.154.84',                    # icinga1001.wikimedia.org
                    '2620:0:861:3:208:80:154:84',       # icinga1001.wikimedia.org
                    '208.80.153.74',                    # icinga2001.wikimedia.org
                    '2620:0:860:3:208:80:153:74',       # icinga2001.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.32.16',                      # deploy1001.eqiad.wmnet
                    '2620:0:861:103:10:64:32:16',       # deploy1001.eqiad.wmnet
                    '10.192.32.24',                     # deploy2001.codfw.wmnet
                    '2620:0:860:103:10:192:32:24',      # deploy2001.codfw.wmnet
                ],
            'puppet_frontends' => [
                    '10.64.16.73',                # puppetmaster1001.eqiad.wmnet
                    '2620:0:861:102:10:64:16:73', # puppetmaster1001.eqiad.wmnet
                    '10.192.0.27',                # puppetmaster2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:27', # puppetmaster2001.codfw.wmnet
                ],
            'mysql_root_clients' => [
                    # ipv6 interfaces are not yet allowed due to mysql grants
                    # do not put dns names or hostnames here, only ipv4
                    '10.64.0.122',                 # db1115.eqiad.wmnet
                    '10.192.48.91',                # db2093.codfw.wmnet
                    '10.64.32.20',                 # neodymium.eqiad.wmnet
                    '10.192.0.140',                # sarin.codfw.wmnet
                    '10.64.32.25',                 # cumin1001.eqiad.wmnet
                    '10.192.48.16',                # cumin2001.codfw.wmnet
                ],
            'kafka_brokers_main' => [
                    '10.64.0.11',                   # kafka1001.eqiad.wmnet
                    '2620:0:861:101:10:64:0:11',    # kafka1001.eqiad.wmnet
                    '10.64.16.41',                  # kafka1002.eqiad.wmnet
                    '2620:0:861:102:10:64:16:41',   # kafka1002.eqiad.wmnet
                    '10.64.32.127',                 # kafka1003.eqiad.wmnet
                    '2620:0:861:103:10:64:32:127',  # kafka1003.eqiad.wmnet
                    '10.192.0.139',                 # kafka2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:139',  # kafka2001.codfw.wmnet
                    '10.192.16.169',                # kafka2002.codfw.wmnet
                    '2620:0:860:102:10:192:16:169', # kafka2002.codfw.wmnet
                    '10.192.32.150',                # kafka2003.codfw.wmnet
                    '2620:0:860:103:10:192:32:150', # kafka2003.codfw.wmnet
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
                    '10.64.0.175',                 # kafka-jumbo1001.eqiad.wmnet
                    '2620:0:861:101:10:64:0:175',  # kafka-jumbo1001.eqiad.wmnet
                    '10.64.0.176',                 # kafka-jumbo1002.eqiad.wmnet
                    '2620:0:861:101:10:64:0:176',  # kafka-jumbo1002.eqiad.wmnet
                    '10.64.16.99',                 # kafka-jumbo1003.eqiad.wmnet
                    '2620:0:861:102:10:64:16:99',  # kafka-jumbo1003.eqiad.wmnet
                    '10.64.32.159',                # kafka-jumbo1004.eqiad.wmnet
                    '2620:0:861:103:10:64:32:159', # kafka-jumbo1004.eqiad.wmnet
                    '10.64.32.160',                # kafka-jumbo1005.eqiad.wmnet
                    '2620:0:861:103:10:64:32:160', # kafka-jumbo1005.eqiad.wmnet
                    '10.64.48.117',                # kafka-jumbo1006.eqiad.wmnet
                    '2620:0:861:107:10:64:48:117', # kafka-jumbo1006.eqiad.wmnet
                ],
            'kafka_brokers_logging' => [
                    '10.64.0.181',                  # logstash1010.eqiad.wmnet
                    '2620:0:861:101:10:64:0:181',   # logstash1010.eqiad.wmnet
                    '10.64.16.30',                  # logstash1011.eqiad.wmnet
                    '2620:0:861:102:10:64:16:30',   # logstash1011.eqiad.wmnet
                    '10.64.48.177',                 # logstash1012.eqiad.wmnet
                    '2620:0:861:107:10:64:48:177',  # logstash1012.eqiad.wmnet
                    '10.192.0.112',                 # logstash2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:112',  # logstash2001.codfw.wmnet
                    '10.192.32.180',                # logstash2002.codfw.wmnet
                    '2620:0:860:103:10:192:32:180', # logstash2002.codfw.wmnet
                    '10.192.48.131',                # logstash2003.codfw.wmnet
                    '2620:0:860:104:10:192:48:131', # logstash2003.codfw.wmnet
                ],
            'zookeeper_hosts_main' => [
                    '10.64.0.23',                         # conf1004.eqiad.wmnet
                    '2620:0:861:101:10:64:0:23',          # conf1004.eqiad.wmnet
                    '10.64.16.29',                        # conf1005.eqiad.wmnet
                    '2620:0:861:102:10:64:16:29',         # conf1005.eqiad.wmnet
                    '10.64.48.167',                       # conf1006.eqiad.wmnet
                    '2620:0:861:107:10:64:48:167',        # conf1006.eqiad.wmnet
                    '10.192.0.143',                       # conf2001.codfw.wmnet
                    '2620:0:860:101:1618:77ff:fe5e:a72c', # conf2001.codfw.wmnet
                    '10.192.32.141',                      # conf2002.codfw.wmnet
                    '2620:0:860:103:1618:77ff:fe5e:a175', # conf2002.codfw.wmnet
                    '10.192.48.52',                       # conf2003.codfw.wmnet
                    '2620:0:860:104:1618:77ff:fe5e:a4c2', # conf2003.codfw.wmnet
                ],
            'hadoop_masters' => [
                    '10.64.5.26',                         # an-master1001.eqiad.wmnet
                    '2620:0:861:104:10:64:5:26',          # an-master1001.eqiad.wmnet
                    '10.64.21.110',                       # an-master1002.eqiad.wmnet
                    '2620:0:861:105:10:64:21:110',        # an-master1002.eqiad.wmnet
                    '10.64.36.128',                       # analytics1028.eqiad.wmnet
                    '2620:0:861:106:10:64:36:128',        # analytics1028.eqiad.wmnet
                    '10.64.36.129',                       # analytics1029.eqiad.wmnet
                    '2620:0:861:106:10:64:36:129',        # analytics1029.eqiad.wmnet
                ],
            'druid_public_hosts' => [
                    '10.64.0.35',                         # druid1004.eqiad.wmnet
                    '2620:0:861:101:10:64:0:35',          # druid1004.eqiad.wmnet
                    '10.64.16.172',                       # druid1005.eqiad.wmnet
                    '2620:0:861:102:10:64:16:172',        # druid1005.eqiad.wmnet
                    '10.64.48.171',                       # druid1006.eqiad.wmnet
                    '2620:0:861:107:10:64:48:171',        # druid1006.eqiad.wmnet
                ],
            },
        'labs' => {
            'monitoring_hosts' => [
                    '172.16.7.178', # shinken-02.shinken.eqiad.wmflabs
                ],
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
