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
    String $tcpircbot_host = lookup('tcpircbot_host'),
    Stdlib::Port $tcpircbot_port = lookup('tcpircbot_port'),
    Hash $redis_shards = lookup('redis::shards'),
    String $ganeti_user = lookup('profile::ganeti::rapi::ro_user'),
    String $ganeti_password = lookup('profile::ganeti::rapi::ro_password'),
    Integer $ganeti_timeout = lookup('profile::spicerack::ganeti_rapi_timeout', {'default_value' => 30}),
    Stdlib::HTTPUrl $netbox_api = lookup('netbox::api_url'),
    String $netbox_token_ro = lookup('netbox::ro_token'),
    String $netbox_token_rw = lookup('netbox::rw_token'),
    String $http_proxy = lookup('http_proxy'),
) {
    # Ensure pre-requisite profiles are included
    require profile::conftool::client
    require profile::cumin::master
    require profile::ipmi::mgmt
    require profile::access_new_install

    include service::deploy::common
    include passwords::redis

    # Packages required by spicerack cookbooks
    ensure_packages(['python3-dateutil', 'python3-requests', 'spicerack'])

    $cookbooks_dir = '/srv/deployment/spicerack'

    # Install the cookbooks
    git::clone { 'operations/cookbooks':
        ensure    => 'latest',
        directory => $cookbooks_dir,
    }

    # this directory is created by the debian package however we still manage it to force
    # an auto require on all files under it this directory
    file {'/etc/spicerack':
        ensure  => directory,
        owner   => 'root',
        group   => 'ops',
        mode    => '0550',
        require => Package['spicerack'],
    }


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
        'api_token_ro' => $netbox_token_ro,
        'api_token_rw' => $netbox_token_rw,
    }
    file { '/etc/spicerack/netbox/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => ordered_yaml($netbox_config_data),
    }

    file { '/etc/spicerack/cookbooks':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0550',
    }
    file { '/etc/spicerack/cookbooks/sre.network.cf.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => secret('spicerack/cookbooks/sre.network.cf.yaml'),
    }

    # Configuration file for switching services between datacenters
    # For each discovery record for active-active services, extract the
    # actual dns from monitoring if available.
    $discovery_records = wmflib::service::fetch().filter |$label, $record| {
        $record['discovery'] != undef
    }

    file { '/etc/spicerack/cookbooks/sre.switchdc.services.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
        content => template('profile/spicerack/sre.switchdc.services.yaml.erb')
    }
}
