# Firewall rules to allow wikitech hosts to access prod DBs
#
# Ultimately wikitech will move to prod appservers at which point this
# can be ripped out.
define profile::mariadb::ferm_wikitech(
    Stdlib::Port $port = 3306,
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::eqiad1::cloudweb_hosts'),  # lint:ignore:wmf_styleguide
    ) {

    ferm::service{ 'labweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => "@resolve((${cloudweb_hosts.join(' ')}))",
    }
}
