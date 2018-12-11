# Authdns configuration data
class role::authdns::data {
    # Our DNS data repo URL
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    # These are all of the public addresses the Internet finds us at
    $ns_addrs = {
        ns0-v4 => { address => '208.80.154.238',     prefixlen => '32'  },
        ns1-v4 => { address => '208.80.153.231',     prefixlen => '32'  },
        ns2-v4 => { address => '91.198.174.239',     prefixlen => '32'  },
    }
}
