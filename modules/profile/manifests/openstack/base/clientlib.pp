class profile::openstack::base::clientlib(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::clientrepo':
        version => $version
    }

    class {'::openstack::clientlib':
        version => $version
    }
    contain '::openstack::clientlib'

    class {'::openstack::common':}
    contain '::openstack::common'
}
