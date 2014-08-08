# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1001", "lvs1004" ],
                'esams' => [ "amslvs1", "amslvs3", "lvs3001", "lvs3003" ],
                'ulsfo' => [ "lvs4001", "lvs4003" ],
                default => undef,
            },
            'labs' => $::site ? {
                'pmtpa' => [ "i-00000051" ],
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1002", "lvs1005" ],
                'esams' => [ "amslvs2", "amslvs4", "lvs3002", "lvs3004" ],
                'ulsfo' => [ "lvs4002", "lvs4004" ],
                default => undef,
            },
            'labs' => $::site ? {
                'pmtpa' => [ "i-00000051" ],
                default => undef,
            },
            default => undef,
        },
        # class https needs to be present on the same hosts as the corresponding
        # http services
        'https' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1001', 'lvs1002', 'lvs1004', 'lvs1005' ],
                'esams' => [ 'amslvs1', 'amslvs2', 'amslvs3', 'amslvs4', 'lvs3001', 'lvs3002', 'lvs3003', 'lvs3004' ],
                default => undef,
            },
            'labs' => $::site ? {
                'pmtpa' => [ "i-00000051" ],
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ "lvs1003", "lvs1006" ],
                'esams' => [ ],
                default => undef,
            },
            'labs' => $::site ? {
                'pmtpa' => [ "i-00000051" ],
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
            /^lvs[1-3]$/ => "208.80.152.197",
            /^lvs[4-6]$/ => "208.80.152.196",
            /^lvs100[1-3]$/ => "208.80.154.196",
            /^lvs100[4-6]$/ => "208.80.154.197",
            /^lvs400[12]$/ => "198.35.26.192",
            /^lvs400[34]$/ => "198.35.26.193",
            /^(amslvs|lvs300)[12]$/ => "91.198.174.245",
            /^(amslvs|lvs300)[34]$/ => "91.198.174.246",
            default => "(unspecified)"
            },
        'bgp-nexthop-ipv4' => $::ipaddress_eth0,
        # FIXME: make a Puppet function, or fix facter
        'bgp-nexthop-ipv6' => inline_template("<%= require 'ipaddr'; (IPAddr.new(v6_ip).mask(64) | IPAddr.new(\"::\" + scope.lookupvar(\"::ipaddress\").gsub('.', ':'))).to_s() %>")
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

    # Configuration of PyBal LVS services.
    # NOTE! Double quotation may be needed for passing strings

    # NOTE! This hash is referenced in many other manifests
    $lvs_service_ips = {
        'production' => {
            'text' => {
                'eqiad' => {
                    'textsvc' => '10.2.2.25',
                    'textlb' => '208.80.154.224',
                    'loginlb' => '208.80.154.233',

                    'textlb6' => '2620:0:861:ed1a::1',
                    'loginlb6' => '2620:0:861:ed1a::1:9',

                    'wikipedialb' => "208.80.154.225",
                    'wiktionarylb' => "208.80.154.226",
                    'wikiquotelb' => "208.80.154.227",
                    'wikibookslb' => "208.80.154.228",
                    'wikisourcelb' => "208.80.154.229",
                    'wikinewslb' => "208.80.154.230",
                    'wikiversitylb' => "208.80.154.231",
                    'mediawikilb' => "208.80.154.232",
                    #'foundationlb' => "208.80.154.233",
                    'wikidatalb' => '208.80.154.242',
                    'wikivoyagelb' => "208.80.154.243",

                    'wikimedialb6' => "2620:0:861:ed1a::0",
                    #'wikipedialb6' => "2620:0:861:ed1a::1",
                    'wiktionarylb6' => "2620:0:861:ed1a::2",
                    'wikiquotelb6' => "2620:0:861:ed1a::3",
                    'wikibookslb6' => "2620:0:861:ed1a::4",
                    'wikisourcelb6' => "2620:0:861:ed1a::5",
                    'wikinewslb6' => "2620:0:861:ed1a::6",
                    'wikiversitylb6' => "2620:0:861:ed1a::7",
                    'mediawikilb6' => "2620:0:861:ed1a::8",
                    'foundationlb6' => "2620:0:861:ed1a::9",
                    'wikidatalb6' => "2620:0:861:ed1a::12",
                    'wikivoyagelb6' => "2620:0:861:ed1a::13",
                },
                'esams' => {
                    'textsvc'   => '10.2.3.25',
                    'textlb'    => '91.198.174.192',
                    'loginlb'   => '91.198.174.201',

                    'textlb6'   => '2620:0:862:ed1a::1',
                    'loginlb6'  => '2620:0:862:ed1a::1:9',
                },
                'ulsfo' => {
                    'textlb'    => '198.35.26.96',
                    'loginlb'   => '198.35.26.105',

                    'textlb6'   => '2620:0:863:ed1a::1',
                    'loginlb6'  => '2620:0:863:ed1a::1:9',
                },
            },
            'https' => {
                'eqiad' => {
                    'wikimedialbsecure' => "208.80.154.224",
                    'wikipedialbsecure' => "208.80.154.225",
                    'bitslbsecure' => "208.80.154.234",
                    'uploadlbsecure' => '208.80.154.240',
                    'wiktionarylbsecure' => "208.80.154.226",
                    'wikiquotelbsecure' => "208.80.154.227",
                    'wikibookslbsecure' => "208.80.154.228",
                    'wikisourcelbsecure' => "208.80.154.229",
                    'wikinewslbsecure' => "208.80.154.230",
                    'wikiversitylbsecure' => "208.80.154.231",
                    'mediawikilbsecure' => "208.80.154.232",
                    'foundationlbsecure' => "208.80.154.233",
                    'mobilelbsecure' => "208.80.154.236",
                    'wikidatalbsecure' => "208.80.154.242",
                    'wikivoyagelbsecure' => "208.80.154.243",

                    'wikimedialbsecure6' => "2620:0:861:ed1a::0",
                    'wikipedialbsecure6' => "2620:0:861:ed1a::1",
                    'wiktionarylbsecure6' => "2620:0:861:ed1a::2",
                    'wikiquotelbsecure6' => "2620:0:861:ed1a::3",
                    'wikibookslbsecure6' => "2620:0:861:ed1a::4",
                    'wikisourcelbsecure6' => "2620:0:861:ed1a::5",
                    'wikinewslbsecure6' => "2620:0:861:ed1a::6",
                    'wikiversitylbsecure6' => "2620:0:861:ed1a::7",
                    'mediawikilbsecure6' => "2620:0:861:ed1a::8",
                    'foundationlbsecure6' => "2620:0:861:ed1a::9",
                    'bitslbsecure6' => '2620:0:861:ed1a::1:a',
                    'bitslbsecure6-old' => "2620:0:861:ed1a::a",
                    'uploadlbsecure6' => '2620:0:861:ed1a::2:b',
                    'mobilelbsecure6' => '2620:0:861:ed1a::1:c',
                    'mobilelbsecure6-old' => "2620:0:861:ed1a::c",
                    'wikidatalbsecure6' => "2620:0:861:ed1a::12",
                    'wikivoyagelbsecure6' => "2620:0:861:ed1a::13"
                },
                'esams' => {
                    'textlbsecure' => '91.198.174.192',
                    'loginlbsecure' => '91.198.174.201',
                    'bitslbsecure' => '91.198.174.202',
                    'bitslbsecure-old' => "91.198.174.233",
                    'uploadlbsecure' => '91.198.174.208',
                    'mobilelbsecure' => '91.198.174.204',
                    'mobilelbsecure-old' => '91.198.174.236',
                    'donatelbsecure' => '91.198.174.224',

                    'textlb6secure'   => '2620:0:862:ed1a::1',
                    'loginlbsecure6' => '2620:0:862:ed1a::1:9',
                    'bitslbsecure6' => '2620:0:862:ed1a::1:a',
                    'bitslbsecure6-old' => "2620:0:862:ed1a::a",
                    'uploadlbsecure6' => '2620:0:862:ed1a::2:b',
                    'mobilelbsecure6' => '2620:0:862:ed1a::1:c',
                    'mobilelbsecure6-old' => '2620:0:862:ed1a::c',
                },
                'ulsfo' => {}
            },
            'bits' => {
                'eqiad' => { 'bitslb' => "208.80.154.234", 'bitslb6' => '2620:0:861:ed1a::1:a', 'bitslb6-old' => "2620:0:861:ed1a::a", 'bitssvc' => "10.2.2.23" },
                'esams' => { 'bitslb' => '91.198.174.202', 'bitslb-old' => "91.198.174.233", 'bitslb6' => '2620:0:862:ed1a::1:a', 'bitslb6-old' => "2620:0:862:ed1a::a", 'bitssvc' => "10.2.3.23" },
                'ulsfo' => { 'bitslb' => "198.35.26.106", 'bitslb6' => '2620:0:863:ed1a::1:a', 'bitssvc' => "10.2.4.23" },
            },
            'upload' => {
                'eqiad' => { 'uploadlb' => '208.80.154.240', 'uploadlb6' => '2620:0:861:ed1a::2:b', 'uploadsvc' => '10.2.2.24' },
                'esams' => { 'uploadlb' => '91.198.174.208', 'uploadlb6' => '2620:0:862:ed1a::2:b', 'uploadsvc' => '10.2.3.24' },
                'ulsfo' => { 'uploadlb' => '198.35.26.112', 'uploadlb6' => '2620:0:863:ed1a::2:b' },
            },
            'payments' => {
                'pmtpa' => "208.80.152.213",
                'eqiad' => {},
            },
            'apaches' => {
                'eqiad' => "10.2.2.1",
            },
            'rendering' => {
                'eqiad' => "10.2.2.21",
            },
            'api' => {
                'eqiad' => "10.2.2.22",
            },
            'search_pool1' => {
                'eqiad' => "10.2.2.11",
            },
            'search_pool2' => {
                'eqiad' => "10.2.2.12",
            },
            'search_pool3' => {
                'eqiad' => "10.2.2.13",
            },
            'search_pool4' => {
                'eqiad' => "10.2.2.14",
            },
            'search_prefix' => {
                'eqiad' => "10.2.2.15",
            },
            'search_pool5' => {
                'eqiad' => "10.2.2.16",
            },
            'mobile' => {
                'eqiad' => { 'mobilelb' => "208.80.154.236", 'mobilelb6' => '2620:0:861:ed1a::1:c', 'mobilelb6-old' => "2620:0:861:ed1a::c", 'mobilesvc' => "10.2.2.26"},
                'esams' => { 'mobilelb' => '91.198.174.204', 'mobilelb-old' => '91.198.174.236', 'mobilelb6' => '2620:0:862:ed1a::1:c', 'mobilelb6-old' => '2620:0:862:ed1a::c', 'mobilesvc' => '10.2.3.26'},
                'ulsfo' => { 'mobilelb' => '198.35.26.108', 'mobilelb6' => '2620:0:863:ed1a::1:c', 'mobilesvc' => '10.2.4.26'},
            },
            'swift' => {
                'pmtpa' => "10.2.1.27",
                'eqiad' => "10.2.2.27",
            },
            'dns_auth' => {
                'pmtpa' => "208.80.152.214",
                'eqiad' => "208.80.154.238",
            },
            'dns_rec' => {
                'pmtpa' => { 'dns_rec' => "208.80.152.215", 'dns_rec6' => "2620:0:860:ed1a::f" },
                'eqiad' => { 'dns_rec' => "208.80.154.239", 'dns_rec6' => "2620:0:861:ed1a::f" },
            },
            'osm' => {
                'pmtpa' => "208.80.152.216",
                'eqiad' => "208.80.154.244",
            },
            'misc_web' => {
                'pmtpa' => { 'misc_web' => '208.80.152.217', 'misc_web6' => '2620:0:860:ed1a::11' },
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
        },
        'labs' => {
            'text' => {
                'pmtpa' => "10.4.0.4",
            },
            'apaches' => {
                'pmtpa' => "10.4.0.254",
            },
            'rendering' => {
                # Used to be 10.4.0.252
                'pmtpa' => [ '10.4.0.166', '10.4.0.187', ],
            },
            'api' => {
                'pmtpa' => "10.4.0.253",
            },
            'bits' => {
                'pmtpa' => "10.4.0.252",
            },
            'search_pool1' => {},
            'search_pool2' => {},
            'search_pool3' => {},
            'dns_auth' => {},
            'dns_rec' => {},
            'https' => {},
            'misc_web' => {},
            'mobile' => {},
            'ocg' => {},
            'osm' => {},
            'search_pool1' => {},
            'search_pool2' => {},
            'search_pool3' => {},
            'search_pool4' => {},
            'search_pool5' => {},
            'search_poolbeta' => {},
            'search_prefix' => {},
            'swift' => {
                # ms emulator set in July 2013. Beta does not have Swift yet.
                # instance is an unpuppetized hack with nginx proxy.
                'eqiad' => '10.68.16.189',  # deployment-upload.eqiad.wmflabs
                'pmtpa' => '10.4.1.103',  # deployment-upload.pmtpa.wmflabs
            },
            'payments' => {},
            'upload' => {
                'pmtpa' => {
                    'uploadlb'  => [ '10.4.0.166', '10.4.0.187', ],
                    'uploadsvc' => [ '10.4.0.166', '10.4.0.187', ],
                },
            },
            'parsoid' => {},
            'parsoidcache' => {},
            'search' => {},
            'stream' => {},
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
        'public1-esams' => {
            'lvs3001' => '91.198.174.11',
            'lvs3002' => '91.198.174.12',
            'lvs3003' => '91.198.174.13',
            'lvs3004' => '91.198.174.14',
        },
    }

    $service_ips = $lvs_service_ips[$::realm]

    $lvs_services = {
        'text' => {
            'description' => "Main wiki platform LVS service, text.${::site}.wikimedia.org (Varnish)",
            'class' => 'high-traffic1',
            'sites' => [ 'eqiad', 'esams', 'ulsfo' ],
            'ip' => $service_ips['text'][$::site],
            'bgp' => 'yes',
            'depool-threshold' => '.5',
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://en.wikipedia.org/wiki/Main_Page' ],
                },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        'text-https' => {
            'description' => "Main wiki platform LVS service, text.${::site}.wikimedia.org (nginx)",
            'class' => 'high-traffic1',
            'sites' => [ 'ulsfo' ],
            'ip' => $service_ips['text'][$::site],
            'port' => 443,
            'bgp' => 'no',
            'depool-threshold' => '.5',
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "https" => {
            'description' => "HTTPS services",
            'class' => "https",
            'sites' => [ "eqiad", "esams" ],
            'ip' => $service_ips['https'][$::site],
            'port' => 443,
            'scheduler' => 'sh',
            # These IPs are announced by the corresponding HTTP services
            'bgp' => "no",
            'depool-threshold' => ".5",
            'monitors' => {
                #'ProxyFetch' => {
                #    'url' => [ 'https://meta.wikimedia.org/wiki/Main_Page' ],
                #    },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "bits" => {
            'description' => "Site assets (CSS/JS) LVS service, bits.${::site}.wikimedia.org",
            'class' => "high-traffic1",
            'sites' => [ "eqiad", "esams", "ulsfo" ],
            'ip' => $service_ips['bits'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://bits.wikimedia.org/pybal-test-file' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "bits-https" => {
            'description' => "Site assets (CSS/JS) LVS service, bits.${::site}.wikimedia.org",
            'class' => 'high-traffic1',
            'sites' => [ 'ulsfo' ],
            'ip' => $service_ips['bits'][$::site],
            'port' => 443,
            'bgp' => 'no',
            'depool-threshold' => '.5',
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "upload" => {
            'description' => "Images and other media, upload.${::site}.wikimedia.org",
            'class' => "high-traffic2",
            'sites' => [ "eqiad", "esams", "ulsfo" ],
            'ip' => $service_ips['upload'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://upload.wikimedia.org/monitoring/backend' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "upload-https" => {
            'description' => "Images and other media, upload.${::site}.wikimedia.org",
            'class' => "high-traffic2",
            'sites' => [ "ulsfo" ],
            'ip' => $service_ips['upload'][$::site],
            'port' => 443,
            'bgp' => "no",
            'depool-threshold' => ".5",
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "mobile" => {
            'description' => "MediaWiki based mobile site",
            'class' => 'high-traffic1',
            'sites' => [ 'eqiad', 'esams', 'ulsfo' ],
            'ip' => $service_ips['mobile'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".6",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://en.m.wikipedia.org/wiki/Angelsberg' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "mobile-https" => {
            'description' => "MediaWiki based mobile site",
            'class' => 'high-traffic1',
            'sites' => [ 'ulsfo' ],
            'ip' => $service_ips['mobile'][$::site],
            'port' => 443,
            'bgp' => "no",
            'depool-threshold' => ".6",
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "payments" => {
            'description' => "Payments cluster, HTTPS payments.wikimedia.org",
            'class' => "high-traffic2",
            'sites' => [ "pmtpa" ],
            'ip' => $service_ips['payments'][$::site],
            'port' => 443,
            'scheduler' => 'sh',
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'https://payments.wikimedia.org/index.php/Special:SystemStatus' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "dns_rec" => {
            'description' => "Recursive DNS",
            'class' => "high-traffic2",
            'sites' => [ "pmtpa", "eqiad" ],
            'protocol' => "udp",
            'ip' => $service_ips['dns_rec'][$::site],
            'port' => 53,
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'DNSQuery' => {
                    'hostnames' => [ 'en.wikipedia.org', 'www.google.com' ],
                    'fail-on-nxdomain' => "no"
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "osm" => {
            'description' => "OpenStreetMap tiles",
            'class' => "high-traffic2",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['osm'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "misc_web" => {
            'description' => "Miscellaneous web sites Varnish cluster",
            'class' => "high-traffic2",
            'sites' => [ "pmtpa", "eqiad" ],
            'ip' => $service_ips['misc_web'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        'misc_web_https' => {
            'description' => 'Miscellaneous web sites Varnish cluster (HTTPS)',
            'class' => 'high-traffic2',
            'sites' => [ 'pmtpa', 'eqiad' ],
            'ip' => $service_ips['misc_web'][$::site],
            'port' => 443,
            'scheduler' => 'sh',
            # These IPs are announced by the corresponding HTTP services
            'bgp' => 'no',
            'depool-threshold' => '.5',
            'monitors' => {
                'IdleConnection' => $idleconnection_monitor_options
            },
        },
        "apaches" => {
            'description' => "Main MediaWiki application server cluster, appservers.svc.eqiad.wmnet",
            'class' => "low-traffic",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['apaches'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".9",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://en.wikipedia.org/wiki/Main_Page' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
                'RunCommand' => $runcommand_monitor_options
            },
        },
        "rendering" => {
            'description' => "MediaWiki thumbnail rendering cluster, rendering.svc.eqiad.wmnet",
            'class' => "low-traffic",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['rendering'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".74",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://en.wikipedia.org/favicon.ico' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
                'RunCommand' => $runcommand_monitor_options
            },
        },
        "api" => {
            'description' => "MediaWiki API cluster, api.svc.eqiad.wmnet",
            'class' => "low-traffic",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['api'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".6",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://en.wikipedia.org/w/api.php' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
                'RunCommand' => $runcommand_monitor_options
            },
        },
        "search_pool1" => {
            'description' => "Lucene search pool 1",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_pool1'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".3",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/stats' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search_pool2" => {
            'description' => "Lucene search pool 2",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_pool2'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".1",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/stats' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search_pool3" => {
            'description' => "Lucene search pool 3",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_pool3'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".1",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/stats' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search_pool4" => {
            'description' => "Lucene search pool 4",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_pool4'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".1",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/search/enwikinews/us?limit=1' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search_pool5" => {
            'description' => "Lucene search pool 5",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_pool5'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".1",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/search/commonswiki/cat?limit=1' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search_prefix" => {
            'description' => "Lucene search prefix pool",
            'class' => "low-traffic",
            'protocol' => "tcp",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search_prefix'][$::site],
            'port' => 8123,
            'scheduler' => "wrr",
            'bgp' => "yes",
            'depool-threshold' => ".4",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/stats' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "swift" => {
            'description' => "Swift/Ceph media storage",
            'class' => "low-traffic",
            'sites' => [ "pmtpa", "eqiad" ],
            'ip' => $service_ips['swift'][$::site],
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/monitoring/backend' ],
                    },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "parsoid" => {
            'description' => "Parsoid wikitext parser for VisualEditor",
            'class' => "low-traffic",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['parsoid'][$::site],
            'port' => 8000,
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost:8000/' ],
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        'parsoidcache' => {
            'description' => "Varnish caches in front of Parsoid",
            'class' => "high-traffic2",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['parsoidcache'][$::site],
            'port' => 80,
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost' ],
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        "search" => {
            'description' => "Elasticsearch search for MediaWiki",
            'class' => "low-traffic",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['search'][$::site],
            'port' => 9200,
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost:9200/' ],
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        'stream' => {
            'description' => "Websocket/streaming services",
            'class' => "high-traffic2",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['stream'][$::site],
            'port' => 80,
            'bgp' => "yes",
            'depool-threshold' => ".5",
            'scheduler' => 'sh',
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/rcstream_status' ],
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        'stream-https' => {
            'description' => "Websocket/streaming services",
            'class' => "high-traffic2",
            'sites' => [ "eqiad" ],
            'ip' => $service_ips['stream'][$::site],
            'port' => 443,
            'bgp' => 'no',
            'depool-threshold' => ".5",
            'scheduler' => 'sh',
            'monitors' => {
                'ProxyFetch' => {
                    'url' => [ 'http://localhost/rcstream_status' ],
                },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
        'ocg' => {
            'description' => 'Offline Content Generator (e.g. PDF), ocg.svc.eqiad.wmnet',
            'class' => 'high-traffic2',
            'sites' => [ 'eqiad' ],
            'ip' => $service_ips['ocg'][$::site],
            'port' => 8000,
            'bgp' => 'yes',
            'depool-threshold' => '.5',
            'monitors' => {
                'ProxyFetch' => { 'url' => [ 'http://ocg.svc.eqiad.wmnet/?command=health' ] },
                'IdleConnection' => $idleconnection_monitor_options,
            },
        },
    }
}
