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
# [*poolcounter_server*]
#   Address of poolcounter server, if any.
#
# [*logstash_host*]
#   Logstash server.
#
# [*logstash_port*]
#   Logstash port.
#
# [*stl_support*]
#   Whether STL support should be enabled.
#

class thumbor (
    $listen_port = 8800,
    $instance_count = $::processorcount,
    $statsd_host = 'localhost',
    $statsd_port = '8125',
    $statsd_prefix = "thumbor.${::hostname}",
    $poolcounter_server = undef,
    $logstash_host = undef,
    $logstash_port = 11514,
    $stl_support = undef,
) {
    require_package('firejail')
    require_package('python-logstash')
    require_package('binutils') # The find_library() function in ctypes/Python uses objdump

    if (os_version('debian == stretch')) {
        apt::repository {'wikimedia-thumbor':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'stretch-wikimedia',
            components => 'component/thumbor',
            notify     => Exec['apt-get update'],
            before     => [ Package['librsvg2-2'], Package['python-thumbor-wikimedia'] ]
        }

        apt::pin { 'wikimedia-thumbor':
            pin      => 'release c=component/thumbor',
            priority => '1002',
        }
    }

    # We are not planning on installing other jessie servers - T214597
    package { 'python-thumbor-wikimedia':
        ensure          => installed,
    }
    package { 'librsvg2-2':
        ensure          => installed,
    }

    file { '/usr/local/lib/thumbor/':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # We ensure the /srv/log (parent of $out_dir) manually here, as
    # there is no proper class to rely on for this, and starting a
    # separate would be an overkill for now.
    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
    }

    file { ['/srv/thumbor', '/srv/thumbor/tmp', '/srv/log/thumbor']:
        ensure  => directory,
        mode    => '0755',
        owner   => 'thumbor',
        group   => 'thumbor',
        require => File['/srv/log']
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
        require => Package['python-thumbor-wikimedia'],
    }

    file { '/etc/firejail/thumbor.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/thumbor/thumbor.profile.firejail',
        before => Systemd::Unit['thumbor@'],
    }

    # use range(), which returns an array of integers, then interpolate it into
    # an array of strings, to use it as a parameter to thumbor::instance below
    $ports = prefix(range($listen_port + 1, $listen_port + $instance_count), '')

    nginx::site { 'thumbor':
        content => template('thumbor/nginx.conf.erb'),
    }

    haproxy::site { 'thumbor':
        content => template('thumbor/haproxy.cfg.erb'),
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

    systemd::unit { 'thumbor@':
        ensure  => present,
        content => systemd_template('thumbor@'),
        require => Package['python-thumbor-wikimedia'],
    }

    systemd::service { 'thumbor-instances':
        ensure  => present,
        content => systemd_template('thumbor-instances'),
    }

    logrotate::conf { 'thumbor':
        ensure => present,
        source => 'puppet:///modules/thumbor/thumbor.logrotate.conf',
    }

    rsyslog::conf { 'thumbor':
        source   => 'puppet:///modules/thumbor/thumbor.rsyslog.conf',
        priority => 40,
    }

    grub::bootparam { 'cgroup_enable':
        value => 'memory',
    }

    grub::bootparam { 'swapaccount':
        value => '1',
    }

    cron { 'systemd-thumbor-tmpfiles-clean':
        minute   => '*',
        hour     => '*',
        monthday => '*',
        month    => '*',
        weekday  => '*',
        command  => '/bin/systemd-tmpfiles --clean --prefix=/srv/thumbor/tmp',
        user     => 'thumbor',
    }

    file { '/usr/local/bin/generate-thumbor-age-metrics.sh':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/thumbor/generate-thumbor-age-metrics.sh',
    }

    cron { 'process-age-statsd':
        minute   => '*',
        hour     => '*',
        monthday => '*',
        month    => '*',
        weekday  => '*',
        command  => "/usr/local/bin/generate-thumbor-age-metrics.sh | /bin/nc -w 1 -u ${statsd_host} ${statsd_port}",
        user     => 'thumbor',
    }
}
