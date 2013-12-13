class role::puppetproxy {
    system::role { 'puppetproxy':
        description => 'Puppet proxying through haproxy host',
    }

    include base::firewall
    ferm::rule { 'puppet_haproxy':
        rule => 'proto tcp dport 8140 { saddr $ALL_NETWORKS ACCEPT; }'
    }

    class { 'haproxy':
        endpoint_hostname => 'palladium',
        endpoint_ip       => '10.64.16.160',
    }
}
