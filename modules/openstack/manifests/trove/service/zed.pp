# SPDX-License-Identifier: Apache-2.0

class openstack::trove::service::zed(
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Integer             $workers,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    Stdlib::Fqdn        $keystone_fqdn,
    String              $region,
    Stdlib::Port        $api_bind_port,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $trove_guest_rabbit_user,
    String              $trove_guest_rabbit_pass,
    String              $trove_service_user_pass,
    String              $trove_service_project,
    String              $trove_service_user,
    String              $trove_quay_user,
    String              $trove_quay_pass,
    String              $designate_internal_uri,
    String              $trove_dns_zone,
    String              $trove_dns_zone_id,
) {
    require "openstack::serverpackages::zed::${::lsbdistcodename}"

    package { ['python3-trove', 'trove-common', 'trove-api', 'trove-taskmanager', 'trove-conductor']:
        ensure => 'present',
    }

    # Subtemplates of trove.conf are going to want to know what
    #  version this is
    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'novaadmin'
    $keystone_auth_project = 'admin'
    file {
        '/etc/trove/trove.conf':
            content   => template('openstack/zed/trove/trove.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/trove-guestagent.conf':
            content   => template('openstack/zed/trove/trove-guestagent.conf.erb'),
            owner     => 'trove',
            group     => 'trove',
            mode      => '0440',
            show_diff => false,
            notify    => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require   => Package['trove-api'];
        '/etc/trove/policy.yaml':
            source  => 'puppet:///modules/openstack/zed/trove/policy.yaml',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api', 'trove-taskmanager', 'trove-conductor'],
            require => Package['trove-api'];
        '/etc/trove/api-paste.ini':
            source  => 'puppet:///modules/openstack/zed/trove/api-paste.ini',
            owner   => 'trove',
            group   => 'trove',
            mode    => '0644',
            notify  => Service['trove-api'],
            require => Package['trove-api'];
        # This file is not used as far as I know, but the bullseye/victoria package post-install
        #  fails if it is not present.
        '/usr/share/trove-common/api-paste.ini':
            source => 'puppet:///modules/openstack/zed/trove/api-paste.ini',
            owner  => 'trove',
            group  => 'trove',
            mode   => '0644';
    }
}
