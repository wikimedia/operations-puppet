class profile::openstack::base::keystone::apache(
    String $version = lookup('profile::openstack::base::version'),
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
