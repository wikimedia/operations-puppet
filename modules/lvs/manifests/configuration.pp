# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1001", "lvs1004" ],
                'codfw' => [ "lvs2001", "lvs2004" ],
                'esams' => [ "lvs3001", "lvs3003" ],
                'ulsfo' => [ "lvs4001", "lvs4003" ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1002", "lvs1005" ],
                'codfw' => [ "lvs2002", "lvs2005" ],
                'esams' => [ "lvs3002", "lvs3004" ],
                'ulsfo' => [ "lvs4002", "lvs4004" ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1003", "lvs1006" ],
                'codfw' => [ "lvs2003", "lvs2006" ],
                'esams' => [ ],
                'ulsfo' => [ ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
    }

    if $::ipaddress6_eth0 {
        $v6_ip = $::ipaddress6_eth0
    }
    else {
        $v6_ip = "::"
    }

    $pybal = {
        'bgp' => "yes",
        'bgp-peer-address' => $hostname ? {
            /^lvs100[1-3]$/ => "208.80.154.196", # cr1-eqiad
            /^lvs100[4-6]$/ => "208.80.154.197", # cr2-eqiad
            /^lvs200[1-3]$/ => "208.80.153.192", # cr1-codfw
            /^lvs200[4-6]$/ => "208.80.153.193", # cr2-codfw
            /^lvs300[12]$/ => "91.198.174.245",  # cr1-esams
            /^lvs300[34]$/ => "91.198.174.246",  # cr2-knams
            /^lvs400[12]$/ => "198.35.26.192",   # cr1-ulsfo
            /^lvs400[34]$/ => "198.35.26.193",   # cr2-ulsfo
            default => "(unspecified)"
            },
        'bgp-nexthop-ipv4' => $::ipaddress_eth0,
        # FIXME: make a Puppet function, or fix facter
        'bgp-nexthop-ipv6' => inline_template("<%= require 'ipaddr'; (IPAddr.new(@v6_ip).mask(64) | IPAddr.new(\"::\" + scope.lookupvar(\"::ipaddress\").gsub('.', ':'))).to_s() %>")
    }

    $idleconnection_monitor_options = {
        'timeout-clean-reconnect' => 3,
        'max-delay' => 300
    }
    $runcommand_monitor_options = {
        'command' => "/bin/sh",
        'arguments' => "[ '/etc/pybal/runcommand/check-apache', server.host ]",
        'interval' => 60,
        'timeout' => 10,
    }

    # NOTE! This hash is referenced in many other manifests
    # TODO: This has is now hosting default values. It is being phased out as
    # you read this, so please refrain from updating it and update the
    # corresponding hiera configuration
    $lvs_service_ips = {
        'production' => {
            'text' => {
                'codfw' => {
                    'textlb' => '208.80.153.224',
                    'loginlb' => '208.80.153.233',
                    'textlb6' => '2620:0:860:ed1a::1',
                    'loginlb6' => '2620:0:860:ed1a::1:9',
                },
                'eqiad' => {
                    'textsvc' => '10.2.2.25',
                    'textlb' => '208.80.154.224',
                    'loginlb' => '208.80.154.233',

                    'textlb6' => '2620:0:861:ed1a::1',
                    'loginlb6' => '2620:0:861:ed1a::1:9',
                },
                'esams' => {
                    'textsvc'   => '10.2.3.25',
                    'textlb'    => '91.198.174.192',
                    'loginlb'   => '91.198.174.201',

                    'textlb6'   => '2620:0:862:ed1a::1',
                    'loginlb6'  => '2620:0:862:ed1a::1:9',
                },
                'ulsfo' => {
                    'textsvc'   => '10.2.4.25',
                    'textlb'    => '198.35.26.96',
                    'loginlb'   => '198.35.26.105',

                    'textlb6'   => '2620:0:863:ed1a::1',
                    'loginlb6'  => '2620:0:863:ed1a::1:9',
                },
            },
            'bits' => {
                'codfw' => { 'bitslb' => "208.80.153.234", 'bitslb6' => '2620:0:860:ed1a::1:a' },
                'eqiad' => { 'bitslb' => "208.80.154.234", 'bitslb6' => '2620:0:861:ed1a::1:a', 'bitssvc' => "10.2.2.23" },
                'esams' => { 'bitslb' => '91.198.174.202', 'bitslb6' => '2620:0:862:ed1a::1:a', 'bitssvc' => "10.2.3.23" },
                'ulsfo' => { 'bitslb' => "198.35.26.106", 'bitslb6' => '2620:0:863:ed1a::1:a', 'bitssvc' => "10.2.4.23" },
            },
            'upload' => {
                'codfw' => { 'uploadlb' => '208.80.153.240', 'uploadlb6' => '2620:0:860:ed1a::2:b' },
                'eqiad' => { 'uploadlb' => '208.80.154.240', 'uploadlb6' => '2620:0:861:ed1a::2:b', 'uploadsvc' => '10.2.2.24' },
                'esams' => { 'uploadlb' => '91.198.174.208', 'uploadlb6' => '2620:0:862:ed1a::2:b', 'uploadsvc' => '10.2.3.24' },
                'ulsfo' => { 'uploadlb' => '198.35.26.112', 'uploadlb6' => '2620:0:863:ed1a::2:b', 'uploadsvc' => '10.2.4.24' },
            },
            'apaches' => {
                'eqiad' => "10.2.2.1",
                'codfw' => '10.2.1.1',
            },
            'rendering' => {
                'eqiad' => "10.2.2.21",
                'codfw' => "10.2.1.21",
            },
            'api' => {
                'eqiad' => "10.2.2.22",
                'codfw' => '10.2.1.22',
            },
            'mobile' => {
                'codfw' => { 'mobilelb' => "208.80.153.236", 'mobilelb6' => '2620:0:860:ed1a::1:c' },
                'eqiad' => { 'mobilelb' => "208.80.154.236", 'mobilelb6' => '2620:0:861:ed1a::1:c', 'mobilesvc' => "10.2.2.26"},
                'esams' => { 'mobilelb' => '91.198.174.204', 'mobilelb6' => '2620:0:862:ed1a::1:c', 'mobilesvc' => '10.2.3.26'},
                'ulsfo' => { 'mobilelb' => '198.35.26.108', 'mobilelb6' => '2620:0:863:ed1a::1:c', 'mobilesvc' => '10.2.4.26'},
            },
            'swift' => {
                'eqiad' => "10.2.2.27",
                'codfw' => "10.2.1.27",
            },
            'dns_rec' => {
                'eqiad' => { 'dns_rec' => "208.80.154.239", 'dns_rec6' => "2620:0:861:ed1a::3:fe" },
                'codfw' => { 'dns_rec' => "208.80.153.254", 'dns_rec6' => "2620:0:860:ed1a::3:fe" },
                'esams' => { 'dns_rec' => "91.198.174.216", 'dns_rec6' => "2620:0:862:ed1a::3:fe" },
            },
            'osm' => {
                'eqiad' => "208.80.154.244",
            },
            'misc_web' => {
                'eqiad' => { 'misc_web' => '208.80.154.241', 'misc_web6' => '2620:0:861:ed1a::11' },
            },
            'parsoid' => {
                'eqiad' => "10.2.2.28",
            },
            'parsoidcache' => {
                'eqiad' => { 'parsoidlb' => '208.80.154.248', 'parsoidlb6' => '2620:0:861:ed1a::3:14', 'parsoidsvc' => '10.2.2.29' },
            },
            'search' => {
                'eqiad' => "10.2.2.30",
            },
            'stream' => {
                'eqiad' => {'streamlb' => '208.80.154.249', 'streamlb6' => '2620:0:861:ed1a::3:15'}
            },
            'ocg' => {
                'eqiad' => '10.2.2.31',
            },
            'mathoid' => {
                'eqiad' => "10.2.2.20",
            },
            'citoid' => {
                'eqiad' => "10.2.2.19",
            },
            'cxserver' => {
                'eqiad' => "10.2.2.18",
            },
            'graphoid' => {
                'eqiad' => "10.2.2.15",
            },
            'restbase' => {
                'eqiad' => "10.2.2.17",
            },

            'zotero' => {
                'eqiad' => "10.2.2.16",
            },
        },
        'labs' => {
            'text' => {
            },
            'apaches' => {
            },
            'rendering' => {
            },
            'api' => {
            },
            'bits' => {
            },
            'dns_rec' => {},
            'mathoid' => {},
            'citoid' => {},
            'cxserver' => {},
            'graphoid' => {},
            'misc_web' => {},
            'mobile' => {},
            'ocg' => {},
            'osm' => {},
            'swift' => {},
            'upload' => {
            },
            'parsoid' => {},
            'parsoidcache' => {},
            'search' => {},
            'stream' => {},
            'restbase' => {},
            'zotero' => {},
        }
    }

    $subnet_ips = {
        'public1-a-eqiad' => {
            'lvs1004' => "208.80.154.58",
            'lvs1005' => "208.80.154.59",
            'lvs1006' => "208.80.154.60",
        },
        'public1-b-eqiad' => {
            'lvs1001' => "208.80.154.140",
            'lvs1002' => "208.80.154.141",
            'lvs1003' => "208.80.154.142",
        },
        'public1-c-eqiad' => {
            'lvs1001' => "208.80.154.78",
            'lvs1002' => "208.80.154.68",
            'lvs1003' => "208.80.154.69",
            'lvs1004' => "208.80.154.70",
            'lvs1005' => "208.80.154.71",
            'lvs1006' => "208.80.154.72",
        },
        'public1-d-eqiad' => {
            'lvs1001' => '208.80.155.100',
            'lvs1002' => '208.80.155.101',
            'lvs1003' => '208.80.155.102',
            'lvs1004' => '208.80.155.103',
            'lvs1005' => '208.80.155.104',
            'lvs1006' => '208.80.155.105',
        },
        'private1-a-eqiad' => {
            'lvs1001' => "10.64.1.1",
            'lvs1002' => "10.64.1.2",
            'lvs1003' => "10.64.1.3",
            'lvs1004' => "10.64.1.4",
            'lvs1005' => "10.64.1.5",
            'lvs1006' => "10.64.1.6",
        },
        'private1-b-eqiad' => {
            'lvs1001' => "10.64.17.1",
            'lvs1002' => "10.64.17.2",
            'lvs1003' => "10.64.17.3",
            'lvs1004' => "10.64.17.4",
            'lvs1005' => "10.64.17.5",
            'lvs1006' => "10.64.17.6",
        },
        'private1-c-eqiad' => {
            'lvs1001' => "10.64.33.1",
            'lvs1002' => "10.64.33.2",
            'lvs1003' => "10.64.33.3",
            'lvs1004' => "10.64.33.4",
            'lvs1005' => "10.64.33.5",
            'lvs1006' => "10.64.33.6",
        },
        'private1-d-eqiad' => {
            'lvs1001' => '10.64.49.1',
            'lvs1002' => '10.64.49.2',
            'lvs1003' => '10.64.49.3',
            'lvs1004' => '10.64.49.4',
            'lvs1005' => '10.64.49.5',
            'lvs1006' => '10.64.49.6',
        },
        'public1-a-codfw' => {
            'lvs2001' => "208.80.153.6",
            'lvs2002' => "208.80.153.7",
            'lvs2003' => "208.80.153.8",
            'lvs2004' => "208.80.153.9",
            'lvs2005' => "208.80.153.10",
            'lvs2006' => "208.80.153.11",
        },
        'public1-b-codfw' => {
            'lvs2001' => "208.80.153.39",
            'lvs2002' => "208.80.153.40",
            'lvs2003' => "208.80.153.41",
            'lvs2004' => "208.80.153.36",
            'lvs2005' => "208.80.153.37",
            'lvs2006' => "208.80.153.38",
        },
        'public1-c-codfw' => {
            'lvs2001' => "208.80.153.68",
            'lvs2002' => "208.80.153.69",
            'lvs2003' => "208.80.153.70",
            'lvs2004' => "208.80.153.71",
            'lvs2005' => "208.80.153.72",
            'lvs2006' => "208.80.153.73",
        },
        'public1-d-codfw' => {
            'lvs2001' => '208.80.153.100',
            'lvs2002' => '208.80.153.101',
            'lvs2003' => '208.80.153.102',
            'lvs2004' => '208.80.153.103',
            'lvs2005' => '208.80.153.104',
            'lvs2006' => '208.80.153.105',
        },
        'private1-a-codfw' => {
            'lvs2004' => "10.192.1.4",
            'lvs2005' => "10.192.1.5",
            'lvs2006' => "10.192.1.6",
        },
        'private1-b-codfw' => {
            'lvs2001' => "10.192.17.1",
            'lvs2002' => "10.192.17.2",
            'lvs2003' => "10.192.17.3",
        },
        'private1-c-codfw' => {
            'lvs2001' => "10.192.33.1",
            'lvs2002' => "10.192.33.2",
            'lvs2003' => "10.192.33.3",
            'lvs2004' => "10.192.33.4",
            'lvs2005' => "10.192.33.5",
            'lvs2006' => "10.192.33.6",
        },
        'private1-d-codfw' => {
            'lvs2001' => '10.192.49.1',
            'lvs2002' => '10.192.49.2',
            'lvs2003' => '10.192.49.3',
            'lvs2004' => '10.192.49.4',
            'lvs2005' => '10.192.49.5',
            'lvs2006' => '10.192.49.6',
        },
        'public1-esams' => {
            'lvs3001' => '91.198.174.11',
            'lvs3002' => '91.198.174.12',
            'lvs3003' => '91.198.174.13',
            'lvs3004' => '91.198.174.14',
        },
    }

    $service_ips = hiera('lvs::configuration::lvs_service_ips', $lvs_service_ips[$::realm])

    $lvs_services = hiera('lvs::configuration::lvs_services')
}
