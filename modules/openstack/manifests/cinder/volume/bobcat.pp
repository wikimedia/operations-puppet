# SPDX-License-Identifier: Apache-2.0

class openstack::cinder::volume::bobcat(
    $version,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String[1]           $db_user,
    String[1]           $db_pass,
    String[1]           $db_name,
    Stdlib::Fqdn        $db_host,
    String[1]           $region,
    String[1]           $ceph_pool,
    String[1]           $ceph_rbd_client_name,
    String[1]           $rabbit_user,
    String[1]           $rabbit_pass,
    String[1]           $libvirt_rbd_cinder_uuid,
    Array[String]       $all_backend_names,
    String[1]           $backend_type,
    String[1]           $backend_name,
    String[1]           $lvm_volume_group,
) {
    require "openstack::serverpackages::bobcat::${::lsbdistcodename}"
    require 'openstack::cinder::user'

    package { 'cinder-volume':
        ensure => 'present',
    }
    package { 'tgt':
        ensure => 'present',
    }

    file {
        # Override the package init module to specify cinder-volume.conf
        '/etc/init.d/cinder-volume':
            source  => 'puppet:///modules/openstack/bobcat/cinder/cinder-volume',
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['cinder-volume'],
            require => Package['cinder-volume'];
    }

    file { '/etc/cinder/cinder-volume.conf':
        content   => template('openstack/bobcat/cinder/cinder-volume.conf.erb'),
        owner     => 'cinder',
        group     => 'cinder',
        mode      => '0440',
        show_diff => false,
    }
}
