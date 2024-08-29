# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::keystone::apache(
    String $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::base::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::base::public_bind_port'),
) {
    class { '::httpd':
        modules => ['proxy_uwsgi', 'auth_openidc'],
    }

    httpd::site { 'proxy-wsgi-keystone':
        ensure  => 'present',
        content => template("openstack/${version}/keystone/apache.conf.erb"),
    }
}
