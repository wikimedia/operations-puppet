# authdns role classes, heavily relying on the authdns role module

class role::authdns::base {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    $nameservers = [
            'ns0.wikimedia.org',
            'ns1-mexia.wikimedia.org',
            'ns1-baham.wikimedia.org',
            'ns2.wikimedia.org',
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

    class { 'authdns':
        fqdn          => 'ns0.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
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
        fqdn          => 'ns1-mexia.wikimedia.org',
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

    class { 'authdns':
        fqdn          => 'ns1-baham.wikimedia.org',
        ipaddress     => $ipv4,
        ipaddress6    => $ipv6,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
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
        fqdn          => 'ns2.wikimedia.org',
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
