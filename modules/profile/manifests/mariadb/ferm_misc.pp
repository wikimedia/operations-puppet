# Firewall rules for the misc db host used by internet-facing websites.
# We need special rules to allow access for some services which
# run on hosts with public IPs.
class profile::mariadb::ferm_misc (
    Stdlib::Host $netmon_server = lookup('netmon_server'),
    Array[Stdlib::Host] $netmon_servers_failover = lookup('netmon_servers_failover'),
) {
    ferm::service { 'netmon-librenms':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "@resolve((${netmon_server} ${netmon_servers_failover.join(' ')}))"
    }

    ferm::service { 'netbox-librenms-reports':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((netbox1002.eqiad.wmnet netbox2002.codfw.wmnet))',
    }
    ferm::service { 'rt':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(moscovium.eqiad.wmnet)',
    }

    ferm::service { 'exim':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((mx1001.wikimedia.org mx2001.wikimedia.org wiki-mail-eqiad.wikimedia.org wiki-mail-codfw.wikimedia.org))',
    }

    ferm::service { 'idp_staging':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((idp-test1002.wikimedia.org idp-test2002.wikimedia.org))',
    }

    ferm::service { 'idp':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((idp1002.wikimedia.org idp1003.wikimedia.org idp2002.wikimedia.org idp2003.wikimedia.org))',
    }
}
