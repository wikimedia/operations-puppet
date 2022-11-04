# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::service::yoga(
    Stdlib::Port $api_bind_port,
) {
    require "openstack::serverpackages::yoga::${::lsbdistcodename}"
    require 'openstack::cinder::user'
    # config should have been declared via a profile, with proper hiera, and is
    # here only for ordering/dependency purposes:
    require 'openstack::cinder::config::yoga'

    package { 'cinder-api':
        ensure => 'present',
    }
    package { 'cinder-scheduler':
        ensure => 'present',
    }
    package { 'cinder-volume':
        ensure => 'present',
    }

    file {
        '/etc/cinder/policy.yaml':
            source  => 'puppet:///modules/openstack/yoga/cinder/policy.yaml',
            owner   => 'cinder',
            group   => 'cinder',
            mode    => '0644',
            require => Package['cinder-api'];
        '/etc/cinder/resource_filters.json':
            source  => 'puppet:///modules/openstack/yoga/cinder/resource_filters.json',
            owner   => 'cinder',
            group   => 'cinder',
            mode    => '0644',
            require => Package['cinder-api'];
        '/etc/init.d/cinder-api':
            content => template('openstack/yoga/cinder/cinder-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['cinder-api'],
            require => Package['cinder-api'];
        '/etc/cinder/cinder-api-uwsgi.ini':
            content => template('openstack/yoga/cinder/cinder-api-uwsgi.ini'),
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['cinder-api'],
            require => Package['cinder-api'];
    }
}
