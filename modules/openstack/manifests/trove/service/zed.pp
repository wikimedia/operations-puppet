# SPDX-License-Identifier: Apache-2.0

class openstack::trove::service::zed(
    Array[Stdlib::Fqdn] $memcached_nodes,
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
    Boolean             $enforce_policy_scope,
    Boolean             $enforce_new_policy_defaults,
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

    # Apply https://review.opendev.org/c/openstack/trove/+/869511
    # (Hopefully fixed after Zed)
    $instance_file_to_patch = '/usr/lib/python3/dist-packages/trove/instance/models.py'
    $instance_patch_file = "${instance_file_to_patch}.patch"
    file {$instance_patch_file:
        source => 'puppet:///modules/openstack/zed/trove/hacks/instance/models.py.patch',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${instance_patch_file}":
        command => "/usr/bin/patch --forward ${instance_file_to_patch} ${instance_patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${instance_file_to_patch} ${instance_patch_file}",
        require => [File[$instance_patch_file], Package['trove-api']],
        notify  => Service['trove-api', 'trove-taskmanager'],
    }

    $taskmanager_file_to_patch = '/usr/lib/python3/dist-packages/trove/taskmanager/models.py'
    $taskmanager_patch_file = "${taskmanager_file_to_patch}.patch"
    file {$taskmanager_patch_file:
        source => 'puppet:///modules/openstack/zed/trove/hacks/taskmanager/models.py.patch',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${taskmanager_patch_file}":
        command => "/usr/bin/patch --forward ${taskmanager_file_to_patch} ${taskmanager_patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${taskmanager_file_to_patch} ${taskmanager_patch_file}",
        require => [File[$taskmanager_patch_file], Package['trove-api']],
        notify  => Service['trove-api', 'trove-taskmanager'],
    }




}
