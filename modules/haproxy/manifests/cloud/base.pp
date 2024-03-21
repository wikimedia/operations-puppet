# == Class: haproxy::cloud::base
#
# This is only for use in CloudVPS. The main use is for wikireplica proxy vms
# and highly available clusters using keepalived and Neutron ports.
# The config is expected to be peculiar to the needs of CloudVPS and may not work
# elsewhere.
#
# === Parameters
#
# [*maintemplate*]
#   If using a special global config, you can specify it here.
#

class haproxy::cloud::base (
    Stdlib::Filesource $mainfile = 'puppet:///modules/haproxy/cloud/haproxy.cfg',
) {
    package { 'haproxy':
        ensure => installed,
    }

    ensure_packages(['socat'])

    file { '/etc/haproxy/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/haproxy/haproxy.cfg':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => $mainfile,
    }

    # this file is loaded as environmentfile in the .service file shipped by
    # the debian package in Buster
    file { '/etc/default/haproxy':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "EXTRAOPTS='-f /etc/haproxy/conf.d/'\n",
        notify  => Service['haproxy'],
    }

    logrotate::conf { 'haproxy':
        ensure => present,
        source => 'puppet:///modules/haproxy/cloud/logging/haproxy.logrotate',
    }

    rsyslog::conf { 'haproxy':
          source   => 'puppet:///modules/haproxy/cloud/logging/haproxy.rsyslog',
          priority => 49,
    }

    service { 'haproxy':
        ensure    => 'running',
        subscribe => [
            File['/etc/haproxy/haproxy.cfg'],
            File['/etc/default/haproxy'],
        ],
        restart   => '/usr/bin/systemctl reload haproxy.service'
    }
}
