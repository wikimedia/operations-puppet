class openstack::firewall {
    include base::firewall

    $labs_private_net = '10.0.0.0/0'
    if ($::site == 'codfw') {
        # TODO!  codfw will need something
        # like this when the ip range is assigned.
        # $labs_nodes = '10.4.16.0/24'
        # virt1000
        $other_master = '208.80.154.18'
    } elsif ($::site == 'eqiad') {
        $labs_nodes = '10.64.20.0/24'
        $other_master = '208.80.153.14'
    }

    # Wikitech ssh
    ferm::rule { 'ssh_public':
        rule => 'saddr (0.0.0.0/0) proto tcp dport (ssh) ACCEPT;',
    }

    # Wikitech HTTP/HTTPS
    ferm::rule { 'http_public':
        rule => 'saddr (0.0.0.0/0) proto tcp dport (http https) ACCEPT;',
    }

    # Labs DNS
    ferm::rule { 'dns_public':
        rule => 'saddr (0.0.0.0/0) proto (udp tcp) dport 53 ACCEPT;',
    }

    # Redis replication for keystone
    ferm::rule { 'redis_replication':
        rule => "saddr ($other_master) proto tcp dport (6379) ACCEPT;",
    }

    # internal services to Labs virt servers
    ferm::rule { 'keystone':
        rule => "saddr ($other_master $labs_nodes) proto tcp dport (5000 35357) ACCEPT;",
    }
    ferm::rule { 'mysql_nova':
        rule => "saddr $labs_nodes proto tcp dport (3306) ACCEPT;",
    }
    ferm::rule { 'beam_nova':
        rule => "saddr $labs_nodes proto tcp dport (5672 56918) ACCEPT;",
    }
    ferm::rule { 'glance_api_nova':
        rule => "saddr $labs_nodes proto tcp dport 9292 ACCEPT;",
    }

    # services provided to Labs instances
    ferm::rule { 'puppetmaster':
        rule => "saddr $labs_private_net proto tcp dport 8140 ACCEPT;",
    }
    ferm::rule { 'salt':
        rule => "saddr $labs_private_net proto tcp dport (4505 4506) ACCEPT;",
    }
}
