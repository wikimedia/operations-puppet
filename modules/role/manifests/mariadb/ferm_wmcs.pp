# Firewall rules for the misc db host used by wmcs.
#  We need special rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class role::mariadb::ferm_wmcs {

    $nova_controller = 'labcontrol1001.wikimedia.org'
    $nova_controller_standby = 'labcontrol1002.wikimedia.org'
    $designate_host = 'labservices1001.wikimedia.org'
    $designate_host_standby = 'labservices1002.wikimedia.org'
    $horizon_host = 'californium.wikimedia.org'
    $osm_host = 'silver.wikimedia.org'

    ferm::service{ 'nova_controller':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "@resolve(${nova_controller}) @resolve(${nova_controller_standby})",
    }

    ferm::service{ 'designate':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "@resolve(${designate_host}) @resolve(${designate_host_standby})",
    }

    ferm::service{ 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve(labpuppetmaster1001.wikimedia.org) @resolve(labpuppetmaster1002.wikimedia.org)',
    }

    ferm::service{ 'horizon_and_striker':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "@resolve(${horizon_host})",
    }

    ferm::service{ 'wikitech':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "@resolve(${osm_host})",
    }
}
