class profile::openstack::base::designate::firewall::api(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::Fqdn $nova_controller = lookup('profile::openstack::base::nova_controller'),
    Stdlib::Fqdn $nova_controller_standby = lookup('profile::openstack::base::nova_controller'),
    Stdlib::Fqdn $osm_host = lookup('profile::openstack::base::osm_host'),
) {
    # Open designate API to WMCS web UIs and the commandline on control servers, also prometheus
    $clients_ipv4 = flatten([
        $labweb_hosts,
        $nova_controller,
        $nova_controller_standby,
        $prometheus_nodes,
        $osm_host,
    ])
    $clients_ipv6 = flatten([
        $labweb_hosts,
        $nova_controller,
        $nova_controller_standby,
        $prometheus_nodes,
    ])

    ferm::service { 'designate-api':
        proto  => 'tcp',
        port   => '9001',
        srange => inline_template("(@resolve((<%= @clients_ipv4.join(' ') %>)) @resolve((<%= @clients_ipv6.join(' ') %>), AAAA))")
    }

    # Allow labs instances to hit the designate api.
    # This is not as permissive as it looks; The wmfkeystoneauth
    # plugin (via the password whitelist) only allows 'novaobserver'
    # to authenticate from within labs, and the novaobserver is
    # limited by the designate policy.json to read-only queries.
    include network::constants
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::service { 'designate-api-for-labs':
        proto  => 'tcp',
        port   => '9001',
        srange => "(${labs_networks})",
    }
}
