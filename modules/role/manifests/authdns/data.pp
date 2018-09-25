# Authdns configuration data
class role::authdns::data {
    # Our DNS data repo URL
    $gitrepo = 'https://gerrit.wikimedia.org/r/p/operations/dns.git'

    # These are the real fqdn's of the authdns machines
    # There should normally be a 1:1 correlation between entries
    # in this list and node definitions in manifests/site.pp
    # which "include role::authdns"
    $nameservers = [
            'authdns1001.wikimedia.org',
            'authdns2001.wikimedia.org',
            'multatuli.wikimedia.org',
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
