# authdns role classes, heavily relying on the authdns role module

# XXX Note: things are in a state of flux here to deal with
#   nameserver moves for pmtpa/codfw and related fallout.
# $nameservers should be using the canonical names ns[012],
#   and the fqdn arguments to class authdns should be using
#   those names as well.  They're currently using the real
#   hostnames of the machines so that authdns-update isn't
#   confused by some machines having loopback IPs for other
#   machines' nsX addrs.
# We should put it all back once the transition is complete

class role::authdns::base {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    $nameservers = [
            'rubidium.wikimedia.org',
            'mexia.wikimedia.org',
            'baham.wikimedia.org',
            'eeden.esams.wikimedia.org',
    ]
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    include authdns::ganglia
}

# ns0 @ eqiad
class role::authdns::ns0 inherits role::authdns::base {
    $ipv4 = '208.80.154.238'
    $ipv6 = '2620:0:861:ed1a::e'

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }
    interface::ip { 'authdns_ipv6':
        interface => 'lo',
        address   => $ipv6,
        prefixlen => '128',
    }

    # temporary for pmtpa/codfw transitional purposes
    $mexia_ipv4 = '208.80.152.214'
    $baham_ipv4 = '208.80.153.231'
    interface::ip { 'mexia_ipv4':
        interface => 'lo',
        address   => $mexia_ipv4,
        prefixlen => '32',
    }
    interface::ip { 'baham_ipv4':
        interface => 'lo',
        address   => $baham_ipv4,
        prefixlen => '32',
    }

    class { 'authdns':
        fqdn          => 'rubidium.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
        extra_listeners => [ $mexia_ipv4, $baham_ipv4 ],
    }
}

# ns1/mexia @ pmtpa (being replaced by baham below, both will be live for a time)
class role::authdns::mexia inherits role::authdns::base {
    $ipv4 = '208.80.152.214'
    $ipv6 = '2620:0:860:ed1a::f' # this isn't currently routing to pmtpa anyways,
                                 # and was never a public authdns target addr.
                                 # changed from ::e to avoid sshkey conflict
                                 # with baham below.

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }
    interface::ip { 'authdns_ipv6':
        interface => 'lo',
        address   => $ipv6,
        prefixlen => '128',
    }

    class { 'authdns':
        fqdn          => 'mexia.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

# ns1/baham @ codfw (replacing mexia above, will both be live for a time)
class role::authdns::baham inherits role::authdns::base {
    $ipv4 = '208.80.153.231'
    $ipv6 = '2620:0:860:ed1a::e'

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }
    interface::ip { 'authdns_ipv6':
        interface => 'lo',
        address   => $ipv6,
        prefixlen => '128',
    }

    # temporary for pmtpa/codfw transitional purposes
    $mexia_ipv4 = '208.80.152.214'
    interface::ip { 'mexia_ipv4':
        interface => 'lo',
        address   => $mexia_ipv4,
        prefixlen => '32',
    }

    class { 'authdns':
        fqdn          => 'baham.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
        extra_listeners => [ $mexia_ipv4 ],
    }
}

# ns2 @ esams
class role::authdns::ns2 inherits role::authdns::base {
    $ipv4 = '91.198.174.239'
    $ipv6 = '2620:0:862:ed1a::e'

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }
    interface::ip { 'authdns_ipv6':
        interface => 'lo',
        address   => $ipv6,
        prefixlen => '128',
    }

    class { 'authdns':
        fqdn          => 'eeden.esams.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
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
