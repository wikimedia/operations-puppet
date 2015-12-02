class role::mediawiki::common {
    include ::standard
    include ::geoip
    include ::mediawiki
    include ::mediawiki::nutcracker
    include ::tmpreaper

    ferm::rule { 'skip_nutcracker_conntrack_out':
        desc  => 'Skip outgoing connection tracking for Nutcracker',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto tcp sport (6379 11212) NOTRACK;',
    }

    ferm::rule { 'skip_nutcracker_conntrack_in':
        desc  => 'Skip incoming connection tracking for Nutcracker',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto tcp dport (6379 11212) NOTRACK;',
    }

    ferm::service{ 'ssh_pybal':
        proto  => 'tcp',
        port   => '22',
        srange => '$INTERNAL',
        desc   => 'Allow incoming SSH for pybal health checks',
    }

    include role::scap::target

    monitoring::service { 'mediawiki-installation DSH group':
        description           => 'mediawiki-installation DSH group',
        check_command         => 'check_dsh_groups!mediawiki-installation',
        normal_check_interval => 60,
    }

    $scap_proxies = hiera('scap::dsh::scap_proxies',[])
    if member($scap_proxies, $::fqdn) {
        include scap::proxy

        ferm::service { 'rsyncd_scap_proxy':
            proto  => 'tcp',
            port   => '873',
            srange => '$MW_APPSERVER_NETWORKS',
        }
    }
}

