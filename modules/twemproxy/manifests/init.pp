# == Class: twemproxy
#
# twemproxy (pronounced "two-em-proxy") is a fast and lightweight proxy
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
# [*servers_list*]
#
# List of the servers (in the IP:PORT format) that will be used as
# backends for memcached.
#
# === Examples
#
#  class { 'twemproxy':
#    servers_list => ['192.168.0.1:11211', '192.168.0.2:11211'],
#  }
#
class twemproxy( $servers_list, $config_parameters = {}) {
    tag 'twemproxy'

    $default_config = {
        'listen'               => '127.0.0.1:11211',
        'hash'                 => 'md5',
        'distribution'         => 'ketama',
        'timeout'              => 250,
        'preconnect'           => 'true',
        'redis'                => 'false',
        'auto_eject_hosts'     => 'true',
        'server_retry_timeout' => 30000,
        'server_failure_limit' => 3,
        'server_connections'   => 2,
    }
    $config = merge($default_config, $config_parameters)

    if versioncmp($::lsbdistrelease, '14.04') >= 0 {
        # Ubuntu 14.04 uses a different (saner) package, who has also
        # been renamed. So twemproxy here acts as a proxy.
        class {'twemproxy::nutcracker':
            config       => $::twemproxy::config,
            servers_list => $::twemproxy::server_list
        }
    } else {
        package { 'twemproxy': }

        file { '/etc/init/twemproxy.conf':
            source => 'puppet:///modules/twemproxy/twemproxy.conf',
            notify => Service['twemproxy'],
        }

        file { '/etc/default/twemproxy':
            source  => 'puppet:///modules/twemproxy/default',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['twemproxy'],
        }

        file { '/etc/nutcracker':
            ensure => directory,
            mode   => '0755',
            before => Package['twemproxy'],
        }

        file { '/etc/nutcracker/nutcracker.yml':
            ensure  => present,
            mode    => '0444',
            content => template('twemproxy/config.yml.erb'),
            notify  => Service['twemproxy'],
        }

        service { 'twemproxy':
            ensure   => running,
            provider => upstart,
        }
   }
}
