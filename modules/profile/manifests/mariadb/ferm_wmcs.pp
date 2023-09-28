# @summary Permits access for the cloudweb hosts to access the striker
# database.
class profile::mariadb::ferm_wmcs (
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::eqiad1::labweb_hosts'),
) {
    $port = '3306'

    ferm::service { 'labweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $labweb_hosts,
    }
}
