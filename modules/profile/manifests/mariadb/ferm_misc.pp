# Firewall rules for the misc db host used by internet-facing websites.
# We need special rules to allow access for some services which
# run on hosts with public IPs.
class profile::mariadb::ferm_misc (
    Stdlib::Host $netmon_server = lookup('netmon_server'),
    Array[Stdlib::Host] $netmon_servers_failover = lookup('netmon_servers_failover'),
) {
    firewall::service { 'netmon-librenms':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => [$netmon_server] + $netmon_servers_failover
    }

    firewall::service { 'netbox-librenms-reports':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['netbox1003.eqiad.wmnet', 'netbox2003.codfw.wmnet'],
    }

    firewall::service { 'exim':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['wiki-mail-eqiad.wikimedia.org', 'wiki-mail-codfw.wikimedia.org', 'mx-in1001.wikimedia.org', 'mx-in2001.wikimedia.org'],
    }

    firewall::service { 'idp_staging':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['idp-test1005.wikimedia.org', 'idp-test2005.wikimedia.org'],
    }

    firewall::service { 'idp':
        proto   => 'tcp',
        port    => 3306,
        notrack => true,
        srange  => ['idp1005.wikimedia.org', 'idp2005.wikimedia.org'],
    }
}
