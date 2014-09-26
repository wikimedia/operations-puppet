# authdns role class, heavily relying on the authdns module

class role::authdns {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    include authdns::ganglia

    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    # This list is for the authdns-update functionality, so that it
    #   can go update all the others when run on any one of them
    $nameservers = [
            'rubidium.wikimedia.org',
            'mexia.wikimedia.org',
            'baham.wikimedia.org',
            'eeden.esams.wikimedia.org',
    ]

    # These are all of the public addresses the Internet finds us at
    # (Note the IPv6 ones aren't published yet, not in "real" use)
    $ns_addrs = {
        ns0_v4 => { address => '208.80.154.238',     prefixlen => '32'  },
        ns1_v4 => { address => '208.80.153.231',     prefixlen => '32'  },
        ns2_v4 => { address => '91.198.174.239',     prefixlen => '32'  },
        ns0_v6 => { address => '2620:0:861:ed1a::e', prefixlen => '128' },
        ns1_v6 => { address => '2620:0:860:ed1a::e', prefixlen => '128' },
        ns2_v6 => { address => '2620:0:862:ed1a::e', prefixlen => '128' },
        # mexia addr from pmtpa, to be removed once traffic dies off:
        ns1_v4_old => { address => '208.80.152.214', prefixlen => '32'  },
    };

    $ns_addrs_defs = { interface => 'lo' }

    create_resources(interface::ip, $ns_addrs, $ns_addrs_defs)

    class { 'authdns':
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

class role::authdns::testns {
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'
    class { 'authdns':
        gitrepo       => $gitrepo,
    }
}
