# @summary Permits access for the cloudweb hosts to access the striker
# database.
class profile::mariadb::ferm_wmcs (
    Array[Stdlib::Fqdn] $cloudweb_hosts = lookup('profile::openstack::eqiad1::cloudweb_hosts'),
) {
    $port = '3306'

    ferm::service { 'labweb':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => $cloudweb_hosts,
    }
}
