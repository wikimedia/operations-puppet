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
    $tcpircbot_host = hiera('tcpircbot_host', 'icinga.wikimedia.org'),
    $tcpircbot_port = hiera('tcpircbot_port', 9200),
) {
    # conftool is needed by switchdc
    require ::profile::conftool::client

    include ::service::deploy::common
    include ::passwords::redis
    $redis_password = $passwords::redis::main_password

    # Install dependencies
    require_package([
        'cumin',
        'python-dnspython',
        'python-redis',
        'python-requests',
        'python-yaml',
    ])

    # Setup directories
    file { ['/etc/switchdc', '/etc/switchdc/stages.d']:
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

    $redis_task = 't06_redis'
    # Setup stage's configuration directories
    file { ["/etc/switchdc/stages.d/${redis_task}"]:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        require => File['/etc/switchdc/stages.d'],
    }

    # Install redis configuration
    file { "/etc/switchdc/stages.d/${redis_task}/config.yaml":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template("profile/switchdc/${redis_task}/config.yaml.erb"),
        require => File["/etc/switchdc/stages.d/${redis_task}"],
    }

    file { "/etc/switchdc/stages.d/${redis_task}/jobqueue.yaml":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => ordered_yaml($redis_shards['jobqueue']),
        require => File["/etc/switchdc/stages.d/${redis_task}"],
    }

    file { "/etc/switchdc/stages.d/${redis_task}/sessions.yaml":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => ordered_yaml($redis_shards['sessions']),
        require => File["/etc/switchdc/stages.d/${redis_task}"],
    }

}
