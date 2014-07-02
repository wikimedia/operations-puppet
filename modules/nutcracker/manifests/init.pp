# == Class: nutcracker
#
# nutcracker ( AKA twemproxy ) is a fast and lightweight proxy
# for memcached and redis. It was primarily built to reduce the
# connection count on the backend caching servers.
#
# === Parameters
#
# [*config_parameters*]
#
# Non-standard config parameters for the memcached section of the
# configuration.
#
# [*server_list*]
#
# List of the servers (in the IP:PORT format) that will be used as
# backends for memcached.
#
# === Examples
#
#  class { 'nutcracker':
#    server_list => ['192.168.0.1:11211', '192.168.0.2:11211'],
#  }
#
class nutcracker( $server_list, $config_parameters = {}) {
    tag 'nutcracker'

    $default_config = {
        'listen'               => '127.0.0.1:11211',
        'hash'                 => 'md5',
        'distribution'         => 'ketama',
        'timeout'              => 250,
        'preconnect'           => 'true', # this is quoted on purpose
        'redis'                => 'false',# same here
        'auto_eject_hosts'     => 'true', # same here
        'server_retry_timeout' => 30000,
        'server_failure_limit' => 3,
        'server_connections'   => 2,
    }

    $config = merge($default_config, $config_parameters)

    package {'nutcracker': }

    file { '/etc/default/nutcracker':
        ensure  => present,
        content => 'DAEMON_OPTS="--mbuf-size=65536 "',
        require => Package['nutcracker'],
    }

    file { '/etc/nutcracker/nutcracker.yml':
        ensure  => present,
        mode    => '0444',
        content => template('nutcracker/config.yml.erb'),
        require => File['/etc/default/nutcracker'],
        notify  => Service['nutcracker'],
    }

    # TODO: remove after the transition is complete
    file { ['/etc/init/twemproxy.conf', '/etc/default/twemproxy']:
        ensure => absent
    }

    service { 'nutcracker':
        ensure   => running,
        name     => 'nutcracker',
        provider => upstart,
    }

}
