class profile::openstack::base::nova::spiceproxy::service(
    $version = hiera('profile::openstack::base::version'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    class {'::openstack2::nova::spiceproxy::service':
        active  => $::fqdn == $nova_controller,
        version => $version,
    }

    ferm::rule{'spice_consoles':
        ensure => 'present',
        rule  => 'saddr (0.0.0.0/0) proto (udp tcp) dport 6082 ACCEPT;',
    }
}
