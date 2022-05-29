# SPDX-License-Identifier: Apache-2.0

class openstack::magnum::service::wallaby(
    String $db_user,
    Array[Stdlib::Fqdn] $openstack_controllers,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    String $keystone_admin_uri,
    String $keystone_internal_uri,
    Stdlib::Port $api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
) {
    require "openstack::serverpackages::wallaby::${::lsbdistcodename}"

    package { 'magnum-api':
        ensure => 'present',
    }
    package { 'magnum-conductor':
        ensure => 'present',
    }

    file {
        '/etc/magnum/magnum.conf':
            content   => template('openstack/wallaby/magnum/magnum.conf.erb'),
            owner     => 'magnum',
            group     => 'magnum',
            mode      => '0440',
            show_diff => false,
            notify    => Service['magnum-api', 'magnum-conductor'],
            require   => Package['magnum-api', 'magnum-conductor'];
        '/etc/magnum/policy.yaml':
            source  => 'puppet:///modules/openstack/wallaby/magnum/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['magnum-api', 'magnum-conductor'],
            require => Package['magnum-api', 'magnum-conductor'];
        '/etc/init.d/magnum-api':
            content => template('openstack/wallaby/magnum/magnum-api.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
    }
}
