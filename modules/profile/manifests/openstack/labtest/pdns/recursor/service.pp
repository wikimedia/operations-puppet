class profile::openstack::labtest::pdns::recursor::service(
    $nova_controller = hiera('profile::openstack::labtest::nova_controller'),
    $observer_password = hiera('profile::openstack::labtest::observer_password'),
    $pdns_host = hiera('profile::openstack::labtest::pdns::host'),
    $pdns_recursor = hiera('profile::openstack::labtest::pdns::recursor'),
    $tld = hiera('profile::openstack::labtest::pdns::tld'),
    $private_reverse = hiera('profile::openstack::labtest::pdns::private_reverse'),
    $puppetmaster_hostname = hiera('profile::openstack::labtest::puppetmaster_hostname'),
    ) {

    class {'::profile::openstack::base::pdns::recursor::service':
        nova_controller   => $nova_controller,
        observer_password => $observer_password,
        pdns_host         => $pdns_host,
        pdns_recursor     => $pdns_recursor,
        tld               => $tld,
        private_reverse   => $private_reverse,
    }
}
