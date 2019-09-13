class profile::openstack::base::keystone::hooks(
    $version = hiera('profile::openstack::base::version'),
    String $wsgi_server = lookup('profile::openstack::base::keystone::wsgi_server'),
    ) {

    class { '::openstack::keystone::hooks':
        version     => $version,
        wsgi_server => $wsgi_server,
    }
    contain '::openstack::keystone::hooks'
}
