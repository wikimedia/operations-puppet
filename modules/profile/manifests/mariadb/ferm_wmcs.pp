# Firewall rules for the misc db host used by wmcs.
#  We need special rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class profile::mariadb::ferm_wmcs(
    $eqiad1_nova_controller = hiera('profile::openstack::eqiad1::nova_controller'),
    $eqiad1_nova_controller_standby = hiera('profile::openstack::eqiad1::nova_controller_standby'),
    $designate_host = hiera('profile::openstack::eqiad1::designate_host'),
    $designate_host_standby = hiera('profile::openstack::eqiad1::designate_host_standby'),
    $labweb_hosts = hiera('profile::openstack::eqiad1::labweb_hosts'),
    $cloudweb_dev_hosts = hiera('profile::openstack::codfw1dev::labweb_hosts'),
    $osm_host = hiera('profile::openstack::eqiad1::osm_host'),
    ) {
    $port = '3306'

    ferm::service{ 'eqiad1_nova_controller':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "(@resolve(${eqiad1_nova_controller}) @resolve(${eqiad1_nova_controller_standby}))",
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
    $cloudweb_dev_ips = inline_template("@resolve((<%= @cloudweb_dev_hosts.join(' ') %>))")
    ferm::service{ 'cloudweb_dev':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $cloudweb_dev_ips,
    }
}
