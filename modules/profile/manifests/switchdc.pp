# == Class profile::switchdc
#
# Installs the switchdc software and its configuration
#
# === Parameters
#
# [*redis_shards*]
#   The hash with the Redis shards.
#
# [*tcpircbot_host*]
#   Hostname for the IRC bot.
#
# [*tcpircbot_port*]
#   Port to use with the IRC bot.
#
class profile::switchdc(
    # Configuration
    $redis_shards   = hiera('redis::shards'),
    $tcpircbot_host = hiera('profile::conftool::client::tcpircbot_host', 'icinga.wikimedia.org'),
    $tcpircbot_port = hiera('profile::conftool::client::tcpircbot_port', 9200),
) {
    include ::passwords::redis
    $redis_password = $passwords::redis::main_password

    # Install dependencies
    require_package([
        'cumin',
        'python-conftool',
        'python-dnspython',
        'python-redis',
        'python-requests',
        'python-yaml',
    ])

    # Setup directories
    file { ['/srv/deployment', '/etc/switchdc', '/etc/switchdc/stages.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
    }

    $checkout_dir = '/srv/deployment/switchdc'

    # Install the software
    git::clone { 'operations-switchdc':
        directory => $checkout_dir,
        origin    => 'https://gerrit.wikimedia.org/r/p/operations/switchdc.git',
        branch    => 'master',
        owner     => 'root',
        group     => 'ops',
        require   => File['/srv/deployment'],
    }

    # Install the entry point
    file { '/usr/local/sbin/switchdc':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        content => template('profile/switchdc/switchdc.erb'),
    }

    # Install the global configuration
    file { '/etc/switchdc/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/switchdc/config.yaml.erb'),
        require => File['/etc/switchdc'],
    }

    # Setup stage's configuration directories
    file { ['/etc/switchdc/stages.d/t05_redis']:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        require => File['/etc/switchdc/stages.d'],
    }

    # Install t05_redis configuration
    file { '/etc/switchdc/stages.d/t05_redis/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/switchdc/t05_redis/config.yaml.erb'),
        require => File['/etc/switchdc/stages.d/t05_redis'],
    }

    file { '/etc/switchdc/stages.d/t05_redis/jobqueue.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => ordered_yaml($redis_shards['jobqueue']),
        require => File['/etc/switchdc/stages.d/t05_redis'],
    }

    file { '/etc/switchdc/stages.d/t05_redis/sessions.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => ordered_yaml($redis_shards['sessions']),
        require => File['/etc/switchdc/stages.d/t05_redis'],
    }

}
