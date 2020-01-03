# == Class profile::spicerack
#
# Installs the spicerack library and cookbook entry point and their configuration.
#
# === Parameters
#
# [*tcpircbot_host*]
#   Hostname for the IRC bot.
#
# [*tcpircbot_port*]
#   Port to use with the IRC bot.
#
# [*redis_shards*]
#   A hash of Redis shards, with the top level key `sessions`, containing a hash
#   keyed by data center, and then by shard name, each shard having a host and port
#   key.
#
# [*ganeti_user*]
#   A Ganeti RAPI user name for Spicerack to use.
#
# [*ganeti_password*]
#   The password for the above user.
#

class profile::spicerack(
    String $tcpircbot_host = hiera('tcpircbot_host'),
    Stdlib::Port $tcpircbot_port = hiera('tcpircbot_port'),
    Hash $redis_shards = hiera('redis::shards'),
    String $ganeti_user = hiera('profile::ganeti::rapi::ro_user'),
    String $ganeti_password = hiera('profile::ganeti::rapi::ro_password'),
    Integer $ganeti_timeout = hiera('profile::spicerack::ganeti_rapi_timeout', 30),
    Stdlib::HTTPUrl $netbox_api = lookup('netbox::api_url'),
    String $netbox_token = lookup('netbox::rw_token'),

) {
    # Ensure pre-requisite profiles are included
    require ::profile::conftool::client
    require ::profile::cumin::master
    require ::profile::ipmi::mgmt
    require ::profile::access_new_install
    require ::profile::conftool::client

    include ::service::deploy::common
    include ::passwords::redis

    # Packages required by spicerack cookbooks
    require_package('python3-dateutil', 'python3-requests')

    apt::package_from_component { 'spicerack':
        component => 'component/spicerack',
        packages  => ['spicerack']
    }

    $cookbooks_dir = '/srv/deployment/spicerack'

    # Install the cookbooks
    git::clone { 'operations/cookbooks':
        ensure    => 'latest',
        directory => $cookbooks_dir,
    }

    # Install the global configuration, the directory is already created by the Debian package
    file { '/etc/spicerack/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('profile/spicerack/config.yaml.erb'),
    }

    # Install the Redis-specific configuration
    file { '/etc/spicerack/redis_cluster':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }

    $redis_sessions_data = {
        'password' => $passwords::redis::main_password,
        'shards' => $redis_shards['sessions'],
    }
    file { '/etc/spicerack/redis_cluster/sessions.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => ordered_yaml($redis_sessions_data),
    }

    # Install Ganeti RAPI configuration
    file { '/etc/spicerack/ganeti':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }
    $ganeti_auth_data = {
        'username' => $ganeti_user,
        'password' => $ganeti_password,
        'timeout'  => $ganeti_timeout,
    }
    file { '/etc/spicerack/ganeti/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => ordered_yaml($ganeti_auth_data),
    }
    # Install Netbox backend configuration
    file { '/etc/spicerack/netbox':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }
    $netbox_config_data = {
        'api_url'   => $netbox_api,
        'api_token' => $netbox_token,
    }
    file { '/etc/spicerack/netbox/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => ordered_yaml($netbox_config_data),
    }
}
