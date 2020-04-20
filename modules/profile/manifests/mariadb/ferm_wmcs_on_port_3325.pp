# Firewall rules for the misc db host used by wmcs.
#  We need special rules to allow access for openstack services (which typically
#  run on hosts with public IPs)

class profile::mariadb::ferm_wmcs_on_port_3325(
    Array[Stdlib::Fqdn] $eqiad1_openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::eqiad1::designate_hosts'),
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
    Array[Stdlib::Fqdn] $cloudweb_dev_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    ) {
    $port = '3325'

    ferm::service{ 'openstack_controllers':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "(@resolve((${join($eqiad1_openstack_controllers,' ')})))",
    }

    ferm::service{ 'designate':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "(@resolve((${join($designate_hosts,' ')})))",
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    ferm::service{ 'labweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $labweb_ips,
    }
}
