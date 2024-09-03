# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::keystone::apache(
    String $version = lookup('profile::openstack::base::version'),
    Stdlib::Port $admin_bind_port = lookup('profile::openstack::base::admin_bind_port'),
    Stdlib::Port $public_bind_port = lookup('profile::openstack::base::public_bind_port'),
    Stdlib::HTTPSUrl $idp_server_name = lookup('profile::idp::server_name'),
    String $idp_client_secret = lookup('profile::openstack::base::keystone::oidc_secret'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::base::keystone_api_fqdn'),
    Stdlib::Port $keystone_port = lookup('profile::openstack::base::keystone::public_port'),
) {

    ensure_packages('libapache2-mod-auth-openidc')

    class { '::httpd':
        modules => ['proxy_uwsgi', 'auth_openidc'],
    }

    httpd::site { 'proxy-wsgi-keystone':
        ensure  => 'present',
        content => template("openstack/${version}/keystone/apache.conf.erb"),
    }
}
