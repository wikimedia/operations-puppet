class profile::openstack::base::keystone::apache(
    String $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::base::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::base::public_bind_port'),
) {
    require_package('libapache2-mod-wsgi')
    class { '::httpd':
        modules => ['wsgi'],
    }

    httpd::site { 'wsgi-keystone':
        ensure  => 'present',
        content => template("openstack/${version}/keystone/apache.conf.erb"),
    }
}
