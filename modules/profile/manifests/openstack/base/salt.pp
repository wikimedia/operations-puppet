class profile::manifests::openstack::base::salt(
    $salt_hosts = hiera('profile::openstack::base::salt_hosts'),
    $instance_range = hiera('profile::openstack::base::nova::fixed_range'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    ) {

    ferm::rule{'saltcertcleaning':
        ensure => 'present',
        rule  => "saddr (${designate_host}) proto tcp dport (ssh) ACCEPT;",
    }

    ferm::rule{ 'salt_hosts':
        ensure => 'present',
        rule => "saddr (${instance_range} ${salthosts}) proto tcp dport (4505 4506) ACCEPT;",
    }
}
