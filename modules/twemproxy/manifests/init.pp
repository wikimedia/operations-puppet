# == Class: twemproxy
#
# twemproxy (pronounced "two-em-proxy") is a fast and lightweight proxy
# for memcached and redis. It was primarily built to reduce the
# connection count on the backend caching servers.
#
# === Parameters
#
# [*default*]
#   Puppet file URI or local filesystem path to file that should be
#   used as /etc/default/twemproxy. The file should set a CONFIG var
#   in the environment that points to the twemproxy YAML config file.
#   Defaults to 'puppet:///modules/twemproxy/default'.
#
# === Examples
#
#  class { 'twemproxy':
#    default => 'puppet:///modules/mediawiki/twemproxy.default',
#  }
#
class twemproxy( $default = 'puppet:///modules/twemproxy/default' ) {
    package { 'twemproxy': }

    file { '/etc/init/twemproxy.conf':
        source => 'puppet:///modules/twemproxy/twemproxy.conf',
        notify => Service['twemproxy'],
    }

    file { '/etc/default/twemproxy':
        source  => $default,
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
