# == Class: Thumbor
#
# This Puppet class installs and configures a Thumbor server.
#
# === Parameters
# [*listen_port*]
#   Port to listen to.
#
# [*instance_count*]
#   How many thumbor instances to run on localhost.
#   Listen port for each instance is based off *listen_port*.
#
# [*statsd_host*]
#   Host to send statistics to.
#
# [*statsd_port*]
#   Port to send statistics to.
#
# [*statsd_prefix*]
#   Prefix to use when sending statistics.
#

class thumbor (
    $listen_port = 8800,
    $instance_count = $::processorcount,
    $statsd_host = 'localhost',
    $statsd_port = '8125',
    $statsd_prefix = "thumbor.${::hostname}",
) {
    requires_os('debian >= jessie')

    require_package('python-thumbor-wikimedia')
    require_package('cgroup-tools')

    file { '/usr/local/lib/thumbor/':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/var/log/thumbor':
        ensure => directory,
        owner  => 'thumbor',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/lib/thumbor/tinyrgb.icc':
        ensure => present,
        source => 'puppet:///modules/thumbor/tinyrgb.icc',
    }

    file { '/etc/thumbor.d/60-thumbor-server.conf':
        ensure  => present,
        owner   => 'thumbor',
        group   => 'thumbor',
        mode    => '0440',
        content => template('thumbor/server.conf.erb'),
    }

    $ports = range("${listen_port + 1}", $listen_port + 1 + $instance_count)

    nginx::site { 'thumbor':
        content => template('thumbor/nginx.conf.erb'),
    }

    # Multi instance setup.
    # * Mask default service from package
    # * Provide 'thumbor-instances' to stop and restart all configured
    # instances, e.g. when puppet is disabled or to send 'notify' from puppet.
    thumbor::instance { $ports: }

    exec { 'mask_default_thumbor':
        command => '/bin/systemctl mask thumbor.service',
        creates => '/etc/systemd/system/thumbor.service',
    }

    base::service_unit { 'thumbor@':
        ensure          => present,
        systemd         => true,
        declare_service => false,
    }

    base::service_unit { 'thumbor-instances':
        ensure  => present,
        systemd => true,
    }

    logrotate::conf { 'thumbor':
        ensure => present,
        source => 'puppet:///modules/thumbor/thumbor.logrotate.conf',
    }

    rsyslog::conf { 'thumbor':
        source   => 'puppet:///modules/thumbor/thumbor.rsyslog.conf',
        priority => 40,
    }
}
