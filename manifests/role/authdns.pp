# authdns role classes, heavily relying on the authdns module

class role::authdns::base {
    include standard

    system_role { 'authdns': description => 'Authoritative DNS server' }

    $master = 'ns0.wikimedia.org'
    $nameservers = [
            'ns0.wikimedia.org',
            'ns1.wikimedia.org',
            'ns2.wikimedia.org',
    ]
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    include authdns::monitoring
}

class role::authdns::ns0 inherits role::authdns::base {
    class { 'authdns':
        fqdn          => 'ns0.wikimedia.org',
        ipaddress     => '208.80.152.130',
        managed_iface => 'lo',
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

class role::authdns::ns1 inherits role::authdns::base {
    class { 'authdns':
        fqdn          => 'ns1.wikimedia.org',
        ipaddress     => '208.80.152.142',
        managed_iface => 'lo',
        nameservers   => $nameservers,
        gitrepo       => $gitrepo,
    }
}

class role::authdns::ns2 inherits role::authdns::base {
    class { 'authdns':
        fqdn          => 'ns2.wikimedia.org',
        ipaddress     => '91.198.174.4',
        managed_iface => 'eth0',
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
