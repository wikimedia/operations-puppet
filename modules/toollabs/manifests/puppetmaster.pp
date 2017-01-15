# Puppetmaster used in toollabs only for k8s nodes

class toollabs::puppetmaster {

    class { '::puppet::self::master':
        server => $::fqdn,
    }

    # Auto pull everything every minute!
    class { '::puppetmaster::gitsync':
        run_every_minutes => '1',
    }
}
