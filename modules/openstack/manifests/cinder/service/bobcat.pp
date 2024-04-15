# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::service::bobcat(
    Stdlib::Port $api_bind_port,
) {
    require "openstack::serverpackages::bobcat::${::lsbdistcodename}"
    require 'openstack::cinder::user'
    # config should have been declared via a profile, with proper hiera, and is
    # here only for ordering/dependency purposes:
    require 'openstack::cinder::config::bobcat'

    package { 'cinder-api':
        ensure => 'present',
    }
    package { 'cinder-scheduler':
        ensure => 'present',
    }

    file {
        '/etc/cinder/policy.yaml':
            source  => 'puppet:///modules/openstack/bobcat/cinder/policy.yaml',
            owner   => 'cinder',
            group   => 'cinder',
            mode    => '0644',
            require => Package['cinder-api'];
        '/etc/cinder/resource_filters.json':
            source  => 'puppet:///modules/openstack/bobcat/cinder/resource_filters.json',
            owner   => 'cinder',
            group   => 'cinder',
            mode    => '0644',
            require => Package['cinder-api'];
        '/etc/init.d/cinder-api':
            content => template('openstack/bobcat/cinder/cinder-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['cinder-api'],
            require => Package['cinder-api'];
        '/etc/cinder/cinder-api-uwsgi.ini':
            source  => 'puppet:///modules/openstack/bobcat/cinder/cinder-api-uwsgi.ini',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['cinder-api'],
            require => Package['cinder-api'];
    }
}
