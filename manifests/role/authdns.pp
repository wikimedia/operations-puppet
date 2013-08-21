# authdns role classes, heavily relying on the authdns role module

class role::authdns::base {
    include standard

    system_role { 'authdns': description => 'Authoritative DNS server' }

    $nameservers = [
            'rubidium.wikimedia.org',
            'mexia.wikimedia.org',
            'eeden.esams.wikimedia.org',
    ]
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

# temporarily commented-out, pending end of migration
#   include authdns::monitoring
    include authdns::ganglia
}

# ns0 @ eqiad
class role::authdns::ns0 inherits role::authdns::base {
    $ipv4 = '208.80.154.238'

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }

    class { 'authdns':
        fqdn          => 'rubidium.wikimedia.org',
        ipaddress     => $ipv4,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

# ns1 @ pmtpa
class role::authdns::ns1 inherits role::authdns::base {
    $ipv4 = '208.80.152.214'

    interface::ip { 'authdns_ipv4':
        interface => 'lo',
        address   => $ipv4,
        prefixlen => '32',
    }

    class { 'authdns':
        fqdn          => 'mexia.wikimedia.org',
        ipaddress     => $ipv4,
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

# ns2 @ esams
class role::authdns::ns2 inherits role::authdns::base {
    $ipv4 = '91.198.174.4'

    interface::ip { 'authdns_ipv4':
        interface => 'eth0', # note: this is interface-bound, unlike ns0/ns1
        address   => $ipv4,
        prefixlen => '32',
    }

    class { 'authdns':
        fqdn          => 'eeden.esams.wikimedia.org',
        ipaddress     => $ipv4,
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
