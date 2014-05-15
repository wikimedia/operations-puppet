# == Class: twemproxy
#
# twemproxy (pronounced "two-em-proxy") is a fast and lightweight proxy
# for memcached and redis. It was primarily built to reduce the
# connection count on the backend caching servers.
#
# === Parameters
#
# [*config_file*]
#   Path to twemproxy YAML configuration file. The file itself is not
#   provisioned by the module, since it is assumed that it will
#   accompany the application that is using twemproxy.
#
# === Examples
#
#  class { 'twemproxy':
#    config_file => '/a/common/wmf-config/twemproxy-eqiad.yaml',
#  }
#
class twemproxy( $config_file ) {
    package { 'twemproxy': }

    file { '/etc/init/twemproxy.conf':
        source => 'puppet:///modules/twemproxy/twemproxy.conf',
        notify => Service['twemproxy'],
    }

    file { '/etc/default/twemproxy':
        content => template('twemproxy/twemproxy.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['twemproxy'],
    }

    service { 'twemproxy':
        ensure   => running,
        provider => upstart,
    }
}
