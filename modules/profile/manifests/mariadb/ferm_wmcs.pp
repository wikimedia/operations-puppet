# Firewall rules for the misc db host used by wmcs.
#  We need special rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class profile::mariadb::ferm_wmcs(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::main::nova_controller_standby'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $designate_host_standby = hiera('profile::openstack::main::designate_host_standby'),
    $horizon_host = hiera('profile::openstack::main::horizon_host'),
    $osm_host = hiera('profile::openstack::main::osm_host'),
    ) {

    ferm::service{ 'nova_controller':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "(@resolve(${nova_controller}) @resolve(${nova_controller_standby}))",
    }

    ferm::service{ 'designate':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "(@resolve(${designate_host}) @resolve(${designate_host_standby}))",
    }

    ferm::service{ 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '(@resolve(labpuppetmaster1001.wikimedia.org) @resolve(labpuppetmaster1002.wikimedia.org))',
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
