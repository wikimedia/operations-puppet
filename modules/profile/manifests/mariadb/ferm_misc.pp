# Firewall rules for the misc db host used by internet-facing websites.
# We need special rules to allow access for some services which
# run on hosts with public IPs.
class profile::mariadb::ferm_misc {
    ferm::service { 'netmon-tools-stretch':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(netmon1002.wikimedia.org)',
    }

    ferm::service { 'rt':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(ununpentium.wikimedia.org)',
    }

    ferm::service { 'gerrit':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(cobalt.wikimedia.org)',
    }

    ferm::service { 'exim':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((mx1001.wikimedia.org mx2001.wikimedia.org wiki-mail-eqiad.wikimedia.org wiki-mail-codfw.wikimedia.org))',
    }
}
