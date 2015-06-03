# authdns role class, heavily relying on the authdns module

# Authdns configuration data
class role::authdns::data {
    # Our DNS data repo URL
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    # These are the real fqdn's of the authdns machines
    # There should normally be a 1:1 correlation between entries
    # in this list and node definitions in manifests/site.pp
    # which "include role::authdns"
    $nameservers = [
            'radon.wikimedia.org',
            'baham.wikimedia.org',
            'eeden.wikimedia.org',
    ]

    # These are all of the public addresses the Internet finds us at
    # (Note the IPv6 ones aren't published yet, not in "real" use)
    $ns_addrs = {
        ns0-v4 => { address => '208.80.154.238',     prefixlen => '32'  },
        ns1-v4 => { address => '208.80.153.231',     prefixlen => '32'  },
        ns2-v4 => { address => '91.198.174.239',     prefixlen => '32'  },
        ns0-v6 => { address => '2620:0:861:ed1a::e', prefixlen => '128' },
        ns1-v6 => { address => '2620:0:860:ed1a::e', prefixlen => '128' },
        ns2-v6 => { address => '2620:0:862:ed1a::e', prefixlen => '128' },
    }
}

# This is for an authdns server to use
class role::authdns::server {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    include authdns::ganglia
    include role::authdns::data

    create_resources(
        interface::ip,
        $role::authdns::data::ns_addrs,
        { interface => 'lo' }
    )

    class { 'authdns':
        nameservers => $role::authdns::data::nameservers,
        gitrepo     => $role::authdns::data::gitrepo,
    }
}

# This is for the monitoring host to monitor the shared public addrs
class role::authdns::monitoring {
    include role::authdns::data
    create_resources(authdns::monitoring::global, $role::authdns::data::ns_addrs)
}

# For deploying the basic software config without participating in the full
# role for e.g. public addrs, monitoring, authdns-update, etc.
class role::authdns::testns {
    include role::authdns::data
    class { 'authdns':
        gitrepo    => $role::authdns::data::gitrepo,
        monitoring => false,
    }
}
