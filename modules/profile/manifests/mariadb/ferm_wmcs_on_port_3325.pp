# Firewall rules for the misc db host used by wmcs.
#  We need special rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class profile::mariadb::ferm_wmcs(
    $nova_controller = hiera('profile::openstack::main::nova_controller'),
    $nova_controller_standby = hiera('profile::openstack::main::nova_controller_standby'),
    $designate_host = hiera('profile::openstack::main::designate_host'),
    $designate_host_standby = hiera('profile::openstack::main::designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::main::labweb_hosts'),
    $labtestweb_hosts = hiera('profile::openstack::labtest::labweb_hosts'),
    $osm_host = hiera('profile::openstack::main::osm_host'),
    ) {
    $port = '3325',

    ferm::service{ 'nova_controller':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "(@resolve(${nova_controller}) @resolve(${nova_controller_standby}))",
    }

    ferm::service{ 'designate':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "(@resolve(${designate_host}) @resolve(${designate_host_standby}))",
    }

    ferm::service{ 'wmcs_puppetmasters':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '(@resolve(labpuppetmaster1001.wikimedia.org) @resolve(labpuppetmaster1002.wikimedia.org))',
    }

    ferm::service{ 'wikitech':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "@resolve(${osm_host})",
    }

    # Soon, 'labweb' will replace horizon, striker, and wikitech
    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    ferm::service{ 'labweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $labweb_ips,
    }
    $labtestweb_ips = inline_template("@resolve((<%= @labtestweb_hosts.join(' ') %>))")
    ferm::service{ 'labtestweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $labtestweb_ips,
    }
}
