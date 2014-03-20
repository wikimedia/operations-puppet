# network.pp

class network::constants {
    $external_networks = [
                '91.198.174.0/24',
                '208.80.152.0/22',
                '2620:0:860::/46',
                '198.35.26.0/23',
                '185.15.56.0/22',
                '2a02:ec80::/32',
                ]
    # NOTE: Should we just use stdlib's concat function and just add 10.0.0.0/8
    # to external_networks to populate this one?
    $all_networks = [
            '91.198.174.0/24',
            '208.80.152.0/22',
            '2620:0:860::/46',
            '198.35.26.0/23',
            '185.15.56.0/22',
            '2a02:ec80::/32',
            '10.0.0.0/8',
            ]

    $mediawiki_appservers [
            '10.0.0.0/16',
            '10.64.0.0/22',
            '10.64.16.0/24',
            '208.80.152.0/22',
            '10.64.32.0/22',
            '10.64.48.0/22',
            ]

    $special_hosts = {
        'production' => {
            'bastion_hosts' => [
                    '208.80.152.165', # fenari.wikimedia.org
                    '208.80.154.149', # bast1001.wikimedia.org
                    '91.198.174.113', # hooft.esams.wikimedia.org
                    '198.35.26.5', # bast4001.wikimedia.org
                    '208.80.154.151', # iron.wikimedia.org
                    '2620:0:860:2:21e:c9ff:feea:ab95', # fenari.wikimedia.org
                    '2620:0:861:2:7a2b:cbff:fe09:11ba', # bast1001.wikimedia.org
                    '2620:0:862:1:a6ba:dbff:fe30:d770', # hooft.esams.wikimedia.org
                    '2620:0:863:1:92b1:1cff:fe4d:4249', # bast4001.wikimedia.org
                    '2620:0:861:2:7a2b:cbff:fe09:d5c', # iron.wikimedia.org
                    ],
            'monitoring_hosts' => [
                        '208.80.154.14', # neon.wikimedia.org
                        '2620:0:861:1:7a2b:cbff:fe08:a42f', # neon.wikimedia.org
                        ]
        },
        'labs' => {
            'bastion_hosts' => [
                    '208.80.153.202',
                    '208.80.153.203',
                    '208.80.153.207',
                    '208.80.153.232',
                    '10.4.1.55',
                    '10.4.1.58',
                    '10.4.1.84',
                    '10.4.0.85',
                    ],
            'monitoring_hosts' => [
                    '208.80.153.210',
                    '208.80.153.249',
                    '10.4.1.120',
                    '10.4.1.137',
                    ],
        }
    }

    $all_network_subnets = {
        'production' => {
            'eqiad' => {
                'public' => {
                    'public1-a-eqiad' => {
                        'ipv4' => '208.80.154.0/26',
                        'ipv6' => '2620:0:861:1::/64'
                    },
                    'public1-b-eqiad' => {
                        'ipv4' => '208.80.154.128/26',
                        'ipv6' => '2620:0:861:2::/64'
                    },
                    'public1-c-eqiad' => {
                        'ipv4' => '208.80.154.64/26',
                        'ipv6' => '2620:0:861:3::/64'
                    },
                    'public1-d-eqiad' => {
                        'ipv4' => '208.80.155.96/27',
                        'ipv6' => '2620:0:861:4::/64'
                    },
                },
                'private' => {
                    'private1-a-eqiad' => {
                        'ipv4' => '10.64.0.0/22',
                        'ipv6' => '2620:0:861:101::/64'
                    },
                    'private1-b-eqiad' => {
                        'ipv4' => '10.64.16.0/22',
                        'ipv6' => '2620:0:861:102::/64'
                    },
                    'private1-c-eqiad' => {
                        'ipv4' => '10.64.32.0/22',
                        'ipv6' => '2620:0:861:103::/64'
                    },
                    'private1-d-eqiad' => {
                        'ipv4' => '10.64.48.0/22',
                        'ipv6' => '2620:0:861:107::/64'
                    },
                    'labs-instances1-a-eqiad' => {
                        'ipv4' => '10.68.0.0/24',
                        'ipv6' => '2620:0:861:201::/64'
                    },
                    'labs-instances1-b-eqiad' => {
                        'ipv4' => '10.68.16.0/21',
                        'ipv6' => '2620:0:861:202::/64'
                    },
                    'labs-instances1-c-eqiad' => {
                        'ipv4' => '10.68.32.0/24',
                        'ipv6' => '2620:0:861:203::/64'
                    },
                    'labs-instances1-d-eqiad' => {
                        'ipv4' => '10.68.48.0/24',
                        'ipv6' => '2620:0:861:204::/64'
                    },
                    'labs-hosts1-a-eqiad' => {
                        'ipv4' => '10.64.4.0/24',
                        'ipv6' => '2620:0:861:117::/64'
                    },
                    'labs-hosts1-b-eqiad' => {
                        'ipv4' => '10.64.20.0/24',
                        'ipv6' => '2620:0:861:118::/64'
                    },
                    'labs-support1-c-eqiad' => {
                        'ipv4' => '10.64.37.0/24',
                        'ipv6' => '2620:0:861:119::/64'
                    },
                    'analytics1-a-eqiad' => {
                        'ipv4' => '10.64.5.0/24',
                        'ipv6' => '2620:0:861:104::/64'
                    },
                    'analytics1-b-eqiad' => {
                        'ipv4' => '10.64.21.0/24',
                        'ipv6' => '2620:0:861:105::/64'
                    },
                    'analytics1-c-eqiad' => {
                        'ipv4' => '10.64.36.0/24',
                        'ipv6' => '2620:0:861:106::/64'
                    }
                },
            },
            'esams' => {
                'public' => {
                    'public-services' => {
                        'ipv4' => '91.198.174.0/25',
                        'ipv6' => '2620:0:862:1::/64'
                    },
                    'backup-storage' => {
                        'ipv4' => '91.198.174.128/26',
                        'ipv6' => '2620:0:862:102::/64'
                    },
                },
            },
            'pmtpa' => {
                'public' => {
                    'public-services' => {
                        'ipv4' => '208.80.152.128/26',
                        'ipv6' => '2620:0:860:2::/64'
                    },
                    'public-services-2' => {
                        'ipv4' => '208.80.153.192/26'
                    },
                    'sandbox' => {
                        'ipv4' => '208.80.152.224/27',
                        'ipv6' => '2620:0:860:3::/64'
                    },
                    'squid+lvs' => {
                        'ipv4' => '208.80.152.0/25',
                        'ipv6' => '2620:0:860:1::/64'
                    },
                },
                'private' => {
                    'virt-hosts' => {
                        'ipv4' => '10.4.16.0/24'
                    },
                    'private' => {
                        'ipv4' => '10.0.0.0/16'
                    },
                },
            },
            'ulsfo' => {
                'public' => {
                    'public1-ulsfo' => {
                        'ipv4' => '198.35.26.0/28',
                        'ipv6' => '2620:0:863:1::/64'
                    },
                },
                'private' => {
                    'private1-ulsfo' => {
                        'ipv4' => '10.128.0.0/24',
                        'ipv6' => '2620:0:863:101::/64'
                    },
                },
            },
        },
    }
}

class network::checks {

    include passwords::network
    $snmp_ro_community = $passwords::network::snmp_ro_community

    # Nagios monitoring
    @monitor_group { 'routers':
        description => 'IP routers',
    }

    @monitor_group { 'storage':
        description => 'Storage equipment',
    }

    # Virtual resource for the monitoring host

    @monitor_host { 'cr1-esams':
        ip_address => '91.198.174.245',
        group      => 'routers',
    }
    @monitor_service { 'cr1-esams bgp status':
        host          => 'cr1-esams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'csw1-esams':
        ip_address => '91.198.174.247',
        group      => 'routers',
    }

    @monitor_service { 'csw1-esams bgp status':
        host          => 'csw1-esams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'csw2-esams':
        ip_address => '91.198.174.244',
        group      => 'routers'
    }

    @monitor_service { 'csw2-esams bgp status':
        host          => 'csw2-esams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'cr1-eqiad':
        ip_address => '208.80.154.196',
        group      => 'routers',
    }

    @monitor_service { 'cr1-eqiad interfaces':
        host          => 'cr1-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_service { 'cr1-eqiad bgp status':
        host          => 'cr1-eqiad',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'cr2-eqiad':
        ip_address => '208.80.154.197',
        group      => 'routers',
    }

    @monitor_service { 'cr2-eqiad interfaces':
        host          => 'cr2-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_service { 'cr2-eqiad bgp status':
        host          => 'cr2-eqiad',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'cr1-sdtpa':
        ip_address => '208.80.152.196',
        group      => 'routers',
    }

    @monitor_service { 'cr1-sdtpa interfaces':
        host          => 'cr1-sdtpa',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_service { 'cr1-sdtpa bgp status':
        host          => 'cr1-sdtpa',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'cr2-pmtpa':
        ip_address => '208.80.152.197',
        group      => 'routers',
    }

    @monitor_service { 'cr2-pmtpa interfaces':
        host          => 'cr2-pmtpa',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_service { 'cr2-pmtpa bgp status':
        host          => 'cr2-pmtpa',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgpstate!${snmp_ro_community}",
    }

    @monitor_host { 'mr1-pmtpa':
        ip_address => '10.1.2.3',
        group      => 'routers',
    }

    @monitor_service { 'mr1-pmtpa interfaces':
        host          => 'mr1-pmtpa',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_host { 'mr1-eqiad':
        ip_address => '10.65.0.1',
        group      => 'routers',
    }

    @monitor_service { 'mr1-eqiad interfaces':
        host          => 'mr1-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus!${snmp_ro_community}",
    }

    @monitor_host { 'nas1-a.pmtpa.wmnet':
        ip_address => '10.0.0.253',
        group      => 'storage',
        critical   => true,
    }

    @monitor_host { 'nas1-b.pmtpa.wmnet':
        ip_address => '10.0.0.254',
        group      => 'storage',
        critical   => true,
    }

    @monitor_host { 'nas1001-a.eqiad.wmnet':
        ip_address => '10.64.16.4',
        group      => 'storage',
        critical   => true,
    }

    @monitor_host { 'nas1001-b.eqiad.wmnet':
        ip_address => '10.64.16.5',
        group      => 'storage',
        critical   => true,
    }
}

# This makes the monitoring host include the router group and
# perform the above checks
include icinga::monitor::configuration::variables
if $hostname in $icinga::monitor::configuration::variables::master_hosts {
    include network::checks
}
