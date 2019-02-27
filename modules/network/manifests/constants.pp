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
            'bastion_hosts' => [
                    '208.80.154.86',                    # bast1002.wikimedia.org
                    '2620:0:861:3:208:80:154:86',       # bast1002.wikimedia.org
                    '208.80.153.5',                     # bast2001.wikimedia.org
                    '2620:0:860:1:208:80:153:5',        # bast2001.wikimedia.org
                    '91.198.174.113',                   # bast3002.wikimedia.org
                    '2620:0:862:1:91:198:174:113',      # bast3002.wikimedia.org
                    '198.35.26.6',                      # bast4002.wikimedia.org
                    '2620:0:863:1:198:35:26:6',         # bast4002.wikimedia.org
                    '103.102.166.7',                    # bast5001.wikimedia.org
                    '2001:df2:e500:1:103:102:166:7',    # bast5001.wikimedia.org
                    '208.80.154.151',                   # iron.wikimedia.org
                    '2620:0:861:2:208:80:154:151',      # iron.wikimedia.org
                ],
            'monitoring_hosts' => [
                    '208.80.154.84',                    # icinga1001.wikimedia.org
                    '2620:0:861:3:208:80:154:84',       # icinga1001.wikimedia.org
                    '208.80.153.74',                    # icinga2001.wikimedia.org
                    '2620:0:860:3:208:80:153:74',       # icinga2001.wikimedia.org
                    '208.80.154.82',                    # dbmonitor1001.wikimedia.org
                    '2620:0:861:3:208:80:154:82',       # dbmonitor1001.wikimedia.org
                    '208.80.153.52',                    # dbmonitor2001.wikimedia.org
                    '2620:0:860:2:208:80:153:52',       # dbmonitor2001.wikimedia.org
                ],
            'deployment_hosts' => [
                    '10.64.32.16',                      # deploy1001.eqiad.wmnet
                    '2620:0:861:103:10:64:32:16',       # deploy1001.eqiad.wmnet
                    '10.192.32.24',                     # deploy2001.codfw.wmnet
                    '2620:0:860:103:10:192:32:24',      # deploy2001.codfw.wmnet
                ],
            'maintenance_hosts' => [
                    '10.64.16.77',                      # mwmaint1002.eqiad.wmnet
                    '2620:0:861:102:10:64:16:77',       # mwmaint1002.eqiad.wmnet
                    '10.192.48.45',                     # mwmaint2001.codfw.wmnet
                    '2620:0:860:104:10:192:48:45',      # mwmaint2001.codfw.wmnet
                ],
            'puppet_frontends' => [
                    '10.64.16.73',                # puppetmaster1001.eqiad.wmnet
                    '2620:0:861:102:10:64:16:73', # puppetmaster1001.eqiad.wmnet
                    '10.192.0.27',                # puppetmaster2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:27', # puppetmaster2001.codfw.wmnet
                ],
            'cumin_masters' => [
                    '10.64.32.25',                 # cumin1001.eqiad.wmnet
                    '2620:0:861:103:10:64:32:25',  # cumin1001.eqiad.wmnet
                    '10.192.48.16',                # cumin2001.codfw.wmnet
                    '2620:0:860:104:10:192:48:16', # cumin2001.codfw.wmnet
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
                    '10.64.0.162',                  # logstash1004.eqiad.wmnet
                    '2620:0:861:101:10:64:0:162',   # logstash1004.eqiad.wmnet
                    '10.64.16.185',                 # logstash1005.eqiad.wmnet
                    '2620:0:861:102:10:64:16:185',  # logstash1005.eqiad.wmnet
                    '10.64.48.109',                 # logstash1006.eqiad.wmnet
                    '2620:0:861:107:10:64:48:109',  # logstash1006.eqiad.wmnet
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
            'druid_analytics_hosts' => [
                    '10.64.5.101',                        # druid1001.eqiad.wmnet
                    '2620:0:861:104:10:64:5:101',         # druid1001.eqiad.wmnet
                    '10.64.36.102',                       # druid1002.eqiad.wmnet
                    '2620:0:861:106:10:64:36:102',        # druid1002.eqiad.wmnet
                    '10.64.53.103',                       # druid1003.eqiad.wmnet
                    '2620:0:861:108:10:64:53:103',        # druid1003.eqiad.wmnet
                ],
            'druid_public_hosts' => [
                    '10.64.0.35',                         # druid1004.eqiad.wmnet
                    '2620:0:861:101:10:64:0:35',          # druid1004.eqiad.wmnet
                    '10.64.16.172',                       # druid1005.eqiad.wmnet
                    '2620:0:861:102:10:64:16:172',        # druid1005.eqiad.wmnet
                    '10.64.48.171',                       # druid1006.eqiad.wmnet
                    '2620:0:861:107:10:64:48:171',        # druid1006.eqiad.wmnet
                ],
            'caches' => [
                    '10.64.32.97',                        # cp1045.eqiad.wmnet
                    '2620:0:861:103:10:64:32:97',         # cp1045.eqiad.wmnet
                    '10.64.32.100',                       # cp1048.eqiad.wmnet
                    '2620:0:861:103:10:64:32:100',        # cp1048.eqiad.wmnet
                    '10.64.32.101',                       # cp1049.eqiad.wmnet
                    '2620:0:861:103:10:64:32:101',        # cp1049.eqiad.wmnet
                    '10.64.32.102',                       # cp1050.eqiad.wmnet
                    '2620:0:861:103:10:64:32:102',        # cp1050.eqiad.wmnet
                    '10.64.32.103',                       # cp1051.eqiad.wmnet
                    '2620:0:861:103:10:64:32:103',        # cp1051.eqiad.wmnet
                    '10.64.32.104',                       # cp1052.eqiad.wmnet
                    '2620:0:861:103:10:64:32:104',        # cp1052.eqiad.wmnet
                    '10.64.32.105',                       # cp1053.eqiad.wmnet
                    '2620:0:861:103:10:64:32:105',        # cp1053.eqiad.wmnet
                    '10.64.32.106',                       # cp1054.eqiad.wmnet
                    '2620:0:861:103:10:64:32:106',        # cp1054.eqiad.wmnet
                    '10.64.32.107',                       # cp1055.eqiad.wmnet
                    '2620:0:861:103:10:64:32:107',        # cp1055.eqiad.wmnet
                    '10.64.0.95',                         # cp1058.eqiad.wmnet
                    '2620:0:861:101:10:64:0:95',          # cp1058.eqiad.wmnet
                    '10.64.0.98',                         # cp1061.eqiad.wmnet
                    '2620:0:861:101:10:64:0:98',          # cp1061.eqiad.wmnet
                    '10.64.0.99',                         # cp1062.eqiad.wmnet
                    '2620:0:861:101:10:64:0:99',          # cp1062.eqiad.wmnet
                    '10.64.0.100',                        # cp1063.eqiad.wmnet
                    '2620:0:861:101:10:64:0:100',         # cp1063.eqiad.wmnet
                    '10.64.0.101',                        # cp1064.eqiad.wmnet
                    '2620:0:861:101:10:64:0:101',         # cp1064.eqiad.wmnet
                    '10.64.0.102',                        # cp1065.eqiad.wmnet
                    '2620:0:861:101:10:64:0:102',         # cp1065.eqiad.wmnet
                    '10.64.0.103',                        # cp1066.eqiad.wmnet
                    '2620:0:861:101:10:64:0:103',         # cp1066.eqiad.wmnet
                    '10.64.0.104',                        # cp1067.eqiad.wmnet
                    '2620:0:861:101:10:64:0:104',         # cp1067.eqiad.wmnet
                    '10.64.0.105',                        # cp1068.eqiad.wmnet
                    '2620:0:861:101:10:64:0:105',         # cp1068.eqiad.wmnet
                    '10.64.48.105',                       # cp1071.eqiad.wmnet
                    '2620:0:861:107:10:64:48:105',        # cp1071.eqiad.wmnet
                    '10.64.48.106',                       # cp1072.eqiad.wmnet
                    '2620:0:861:107:10:64:48:106',        # cp1072.eqiad.wmnet
                    '10.64.48.107',                       # cp1073.eqiad.wmnet
                    '2620:0:861:107:10:64:48:107',        # cp1073.eqiad.wmnet
                    '10.64.48.108',                       # cp1074.eqiad.wmnet
                    '2620:0:861:107:10:64:48:108',        # cp1074.eqiad.wmnet
                    '10.64.0.130',                        # cp1075.eqiad.wmnet
                    '2620:0:861:101:10:64:0:130',         # cp1075.eqiad.wmnet
                    '10.64.0.131',                        # cp1076.eqiad.wmnet
                    '2620:0:861:101:10:64:0:131',         # cp1076.eqiad.wmnet
                    '10.64.0.132',                        # cp1077.eqiad.wmnet
                    '2620:0:861:101:10:64:0:132',         # cp1077.eqiad.wmnet
                    '10.64.0.133',                        # cp1078.eqiad.wmnet
                    '2620:0:861:101:10:64:0:133',         # cp1078.eqiad.wmnet
                    '10.64.16.22',                        # cp1079.eqiad.wmnet
                    '2620:0:861:102:10:64:16:22',         # cp1079.eqiad.wmnet
                    '10.64.16.23',                        # cp1080.eqiad.wmnet
                    '2620:0:861:102:10:64:16:23',         # cp1080.eqiad.wmnet
                    '10.64.16.24',                        # cp1081.eqiad.wmnet
                    '2620:0:861:102:10:64:16:24',         # cp1081.eqiad.wmnet
                    '10.64.16.25',                        # cp1082.eqiad.wmnet
                    '2620:0:861:102:10:64:16:25',         # cp1082.eqiad.wmnet
                    '10.64.32.67',                        # cp1083.eqiad.wmnet
                    '2620:0:861:103:10:64:32:67',         # cp1083.eqiad.wmnet
                    '10.64.32.68',                        # cp1084.eqiad.wmnet
                    '2620:0:861:103:10:64:32:68',         # cp1084.eqiad.wmnet
                    '10.64.32.69',                        # cp1085.eqiad.wmnet
                    '2620:0:861:103:10:64:32:69',         # cp1085.eqiad.wmnet
                    '10.64.32.70',                        # cp1086.eqiad.wmnet
                    '2620:0:861:103:10:64:32:70',         # cp1086.eqiad.wmnet
                    '10.64.48.101',                       # cp1087.eqiad.wmnet
                    '2620:0:861:107:10:64:48:101',        # cp1087.eqiad.wmnet
                    '10.64.48.102',                       # cp1088.eqiad.wmnet
                    '2620:0:861:107:10:64:48:102',        # cp1088.eqiad.wmnet
                    '10.64.48.103',                       # cp1089.eqiad.wmnet
                    '2620:0:861:107:10:64:48:103',        # cp1089.eqiad.wmnet
                    '10.64.48.104',                       # cp1090.eqiad.wmnet
                    '2620:0:861:107:10:64:48:104',        # cp1090.eqiad.wmnet
                    '10.64.32.81',                        # cp1099.eqiad.wmnet
                    '2620:0:861:103:10:64:32:81',         # cp1099.eqiad.wmnet
                    '10.192.0.122',                       # cp2001.codfw.wmnet
                    '2620:0:860:101:10:192:0:122',        # cp2001.codfw.wmnet
                    '10.192.0.123',                       # cp2002.codfw.wmnet
                    '2620:0:860:101:10:192:0:123',        # cp2002.codfw.wmnet
                    '10.192.0.124',                       # cp2003.codfw.wmnet
                    '2620:0:860:101:10:192:0:124',        # cp2003.codfw.wmnet
                    '10.192.0.125',                       # cp2004.codfw.wmnet
                    '2620:0:860:101:10:192:0:125',        # cp2004.codfw.wmnet
                    '10.192.0.126',                       # cp2005.codfw.wmnet
                    '2620:0:860:101:10:192:0:126',        # cp2005.codfw.wmnet
                    '10.192.0.127',                       # cp2006.codfw.wmnet
                    '2620:0:860:101:10:192:0:127',        # cp2006.codfw.wmnet
                    '10.192.16.133',                      # cp2007.codfw.wmnet
                    '2620:0:860:102:10:192:16:133',       # cp2007.codfw.wmnet
                    '10.192.16.134',                      # cp2008.codfw.wmnet
                    '2620:0:860:102:10:192:16:134',       # cp2008.codfw.wmnet
                    '10.192.16.135',                      # cp2009.codfw.wmnet
                    '2620:0:860:102:10:192:16:135',       # cp2009.codfw.wmnet
                    '10.192.16.136',                      # cp2010.codfw.wmnet
                    '2620:0:860:102:10:192:16:136',       # cp2010.codfw.wmnet
                    '10.192.16.137',                      # cp2011.codfw.wmnet
                    '2620:0:860:102:10:192:16:137',       # cp2011.codfw.wmnet
                    '10.192.16.138',                      # cp2012.codfw.wmnet
                    '2620:0:860:102:10:192:16:138',       # cp2012.codfw.wmnet
                    '10.192.32.112',                      # cp2013.codfw.wmnet
                    '2620:0:860:103:10:192:32:112',       # cp2013.codfw.wmnet
                    '10.192.32.113',                      # cp2014.codfw.wmnet
                    '2620:0:860:103:10:192:32:113',       # cp2014.codfw.wmnet
                    '10.192.32.114',                      # cp2015.codfw.wmnet
                    '2620:0:860:103:10:192:32:114',       # cp2015.codfw.wmnet
                    '10.192.32.115',                      # cp2016.codfw.wmnet
                    '2620:0:860:103:10:192:32:115',       # cp2016.codfw.wmnet
                    '10.192.32.116',                      # cp2017.codfw.wmnet
                    '2620:0:860:103:10:192:32:116',       # cp2017.codfw.wmnet
                    '10.192.32.117',                      # cp2018.codfw.wmnet
                    '2620:0:860:103:10:192:32:117',       # cp2018.codfw.wmnet
                    '10.192.48.23',                       # cp2019.codfw.wmnet
                    '2620:0:860:104:10:192:48:23',        # cp2019.codfw.wmnet
                    '10.192.48.24',                       # cp2020.codfw.wmnet
                    '2620:0:860:104:10:192:48:24',        # cp2020.codfw.wmnet
                    '10.192.48.25',                       # cp2021.codfw.wmnet
                    '2620:0:860:104:10:192:48:25',        # cp2021.codfw.wmnet
                    '10.192.48.26',                       # cp2022.codfw.wmnet
                    '2620:0:860:104:10:192:48:26',        # cp2022.codfw.wmnet
                    '10.192.48.27',                       # cp2023.codfw.wmnet
                    '2620:0:860:104:10:192:48:27',        # cp2023.codfw.wmnet
                    '10.192.48.28',                       # cp2024.codfw.wmnet
                    '2620:0:860:104:10:192:48:28',        # cp2024.codfw.wmnet
                    '10.192.48.29',                       # cp2025.codfw.wmnet
                    '2620:0:860:104:10:192:48:29',        # cp2025.codfw.wmnet
                    '10.192.48.30',                       # cp2026.codfw.wmnet
                    '2620:0:860:104:10:192:48:30',        # cp2026.codfw.wmnet
                    '10.20.0.107',                        # cp3007.esams.wmnet
                    '2620:0:862:102:10:20:0:107',         # cp3007.esams.wmnet
                    '10.20.0.108',                        # cp3008.esams.wmnet
                    '2620:0:862:102:10:20:0:108',         # cp3008.esams.wmnet
                    '10.20.0.110',                        # cp3010.esams.wmnet
                    '2620:0:862:102:10:20:0:110',         # cp3010.esams.wmnet
                    '10.20.0.165',                        # cp3030.esams.wmnet
                    '2620:0:862:102:10:20:0:165',         # cp3030.esams.wmnet
                    '10.20.0.166',                        # cp3031.esams.wmnet
                    '2620:0:862:102:10:20:0:166',         # cp3031.esams.wmnet
                    '10.20.0.167',                        # cp3032.esams.wmnet
                    '2620:0:862:102:10:20:0:167',         # cp3032.esams.wmnet
                    '10.20.0.168',                        # cp3033.esams.wmnet
                    '2620:0:862:102:10:20:0:168',         # cp3033.esams.wmnet
                    '10.20.0.169',                        # cp3034.esams.wmnet
                    '2620:0:862:102:10:20:0:169',         # cp3034.esams.wmnet
                    '10.20.0.170',                        # cp3035.esams.wmnet
                    '2620:0:862:102:10:20:0:170',         # cp3035.esams.wmnet
                    '10.20.0.171',                        # cp3036.esams.wmnet
                    '2620:0:862:102:10:20:0:171',         # cp3036.esams.wmnet
                    '10.20.0.172',                        # cp3037.esams.wmnet
                    '2620:0:862:102:10:20:0:172',         # cp3037.esams.wmnet
                    '10.20.0.173',                        # cp3038.esams.wmnet
                    '2620:0:862:102:10:20:0:173',         # cp3038.esams.wmnet
                    '10.20.0.174',                        # cp3039.esams.wmnet
                    '2620:0:862:102:10:20:0:174',         # cp3039.esams.wmnet
                    '10.20.0.175',                        # cp3040.esams.wmnet
                    '2620:0:862:102:10:20:0:175',         # cp3040.esams.wmnet
                    '10.20.0.176',                        # cp3041.esams.wmnet
                    '2620:0:862:102:10:20:0:176',         # cp3041.esams.wmnet
                    '10.20.0.177',                        # cp3042.esams.wmnet
                    '2620:0:862:102:10:20:0:177',         # cp3042.esams.wmnet
                    '10.20.0.178',                        # cp3043.esams.wmnet
                    '2620:0:862:102:10:20:0:178',         # cp3043.esams.wmnet
                    '10.20.0.179',                        # cp3044.esams.wmnet
                    '2620:0:862:102:10:20:0:179',         # cp3044.esams.wmnet
                    '10.20.0.180',                        # cp3045.esams.wmnet
                    '2620:0:862:102:10:20:0:180',         # cp3045.esams.wmnet
                    '10.20.0.181',                        # cp3046.esams.wmnet
                    '2620:0:862:102:10:20:0:181',         # cp3046.esams.wmnet
                    '10.20.0.182',                        # cp3047.esams.wmnet
                    '2620:0:862:102:10:20:0:182',         # cp3047.esams.wmnet
                    '10.20.0.184',                        # cp3049.esams.wmnet
                    '2620:0:862:102:10:20:0:184',         # cp3049.esams.wmnet
                    '10.128.0.121',                       # cp4021.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:121',        # cp4021.ulsfo.wmnet
                    '10.128.0.122',                       # cp4022.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:122',        # cp4022.ulsfo.wmnet
                    '10.128.0.123',                       # cp4023.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:123',        # cp4023.ulsfo.wmnet
                    '10.128.0.124',                       # cp4024.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:124',        # cp4024.ulsfo.wmnet
                    '10.128.0.125',                       # cp4025.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:125',        # cp4025.ulsfo.wmnet
                    '10.128.0.126',                       # cp4026.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:126',        # cp4026.ulsfo.wmnet
                    '10.128.0.127',                       # cp4027.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:127',        # cp4027.ulsfo.wmnet
                    '10.128.0.128',                       # cp4028.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:128',        # cp4028.ulsfo.wmnet
                    '10.128.0.129',                       # cp4029.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:129',        # cp4029.ulsfo.wmnet
                    '10.128.0.130',                       # cp4030.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:130',        # cp4030.ulsfo.wmnet
                    '10.128.0.131',                       # cp4031.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:131',        # cp4031.ulsfo.wmnet
                    '10.128.0.132',                       # cp4032.ulsfo.wmnet
                    '2620:0:863:101:10:128:0:132',        # cp4032.ulsfo.wmnet
                    '10.132.0.101',                       # cp5001.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:101',     # cp5001.eqsin.wmnet
                    '10.132.0.102',                       # cp5002.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:102',     # cp5002.eqsin.wmnet
                    '10.132.0.103',                       # cp5003.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:103',     # cp5003.eqsin.wmnet
                    '10.132.0.104',                       # cp5004.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:104',     # cp5004.eqsin.wmnet
                    '10.132.0.105',                       # cp5005.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:105',     # cp5005.eqsin.wmnet
                    '10.132.0.107',                       # cp5007.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:107',     # cp5007.eqsin.wmnet
                    '10.132.0.108',                       # cp5008.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:108',     # cp5008.eqsin.wmnet
                    '10.132.0.109',                       # cp5009.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:109',     # cp5009.eqsin.wmnet
                    '10.132.0.110',                       # cp5010.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:110',     # cp5010.eqsin.wmnet
                    '10.132.0.111',                       # cp5011.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:111',     # cp5011.eqsin.wmnet
                    '10.132.0.112',                       # cp5012.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:112',     # cp5012.eqsin.wmnet
                    '10.132.0.106',                       # cp5006.eqsin.wmnet
                    '2001:df2:e500:101:10:132:0:106',     # cp5006.eqsin.wmnet
                    '208.80.154.42',                      # pinkunicorn.wikimedia.org
                    '2620:0:861:1:208:80:154:42',         # pinkunicorn.wikimedia.org
                ],
            },
        'labs' => {
            'bastion_hosts' => concat([
                    '10.68.17.232', # bastion-01.eqiad.wmflabs
                    '10.68.18.65',  # bastion-02.eqiad.wmflabs
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                    '172.16.1.136', # bastion-eqiad1-01.eqiad.wmflabs
                    '172.16.3.155', # bastion-eqiad1-02.eqiad.wmflabs
                    '172.16.1.135', # bastion-restricted-eqiad1-01.eqiad.wmflabs
                ], hiera('network::allow_ssh_from_ips', [])), # Allow labs projects to setup their own ssh origination points
            'monitoring_hosts' => [
                    '172.16.7.178', # shinken-02.shinken.eqiad.wmflabs
                ],
            'deployment_hosts' => hiera('network::allow_deployment_from_ips', []), # lint:ignore:wmf_styleguide
            'maintenance_hosts' => hiera('network::allow_maintenance_from_ips', []), # lint:ignore:wmf_styleguide
            'cumin_masters' => [  # As seen by labs instances
                    '10.68.18.66',  # bastion-restricted-01.eqiad.wmflabs
                    '10.68.18.68',  # bastion-restricted-02.eqiad.wmflabs
                    '172.16.1.211', # bastion-restricted-eqiad1-02.eqiad.wmflabs
                    '172.16.1.135', # bastion-restricted-eqiad1-01.eqiad.wmflabs
                ],
            'cumin_real_masters' => [  # Where Cumin can be run
                    '208.80.154.158',               # labpuppetmaster1001.wikimedia.org
                    '2620:0:861:2:208:80:154:158',  # labpuppetmaster1001.wikimedia.org
                    '208.80.155.120',               # labpuppetmaster1002.wikimedia.org
                    '2620:0:861:4:208:80:155:120',  # labpuppetmaster1002.wikimedia.org
                ],
            'caches' => [ # So that roles with CACHES in ferm rules can be used in labs
                    '10.68.21.68', # novaproxy-01.project-proxy.eqiad.wmflabs
                    '10.68.21.69', # novaproxy-02.project-proxy.eqiad.wmflabs
                    '172.16.0.164', # proxy-01.project-proxy.eqiad.wmflabs
                    '172.16.0.165', # proxy-02.project-proxy.eqiad.wmflabs
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
