# SPDX-License-Identifier: Apache-2.0
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
    ensure_packages([
        'firejail', 'python-logstash',
        'binutils', # The find_library() function in ctypes/Python uses objdump
    ])

    apt::package_from_component { 'wikimedia-thumbor':
        component => 'component/thumbor',
        packages  => ['librsvg2-2', 'librsvg2-common', 'librsvg2-bin',
                      'python-thumbor-wikimedia'],
        priority  => 1002,
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

    # lint:ignore:wmf_styleguide
    class {'haproxy': logging => true}
    haproxy::site { 'thumbor':
        content => template('thumbor/haproxy.cfg.erb'),
    }

    include haproxy::mtail
    # lint:endignore

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

    systemd::timer::job { 'thumbor_systemd_tmpfiles_clean':
        ensure             => 'present',
        user               => 'thumbor',
        description        => 'clean systemd tmpfiles for thumbor',
        command            => '/bin/systemd-tmpfiles --clean --prefix=/srv/thumbor/tmp',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '1m'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    file { '/usr/local/bin/generate-thumbor-age-metrics.sh':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/thumbor/generate-thumbor-age-metrics.sh',
    }

    file { '/usr/local/bin/generate-thumbor-age-metrics-nc.sh':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/thumbor/generate-thumbor-age-metrics-nc.sh',
    }

    file { '/etc/generate-thumbor-age-metrics':
        ensure  => present,
        mode    => '0555',
        content => template('thumbor/generate-thumbor-age-metrics-nc-config.erb'),
    }

    systemd::timer::job { 'thumbor_process_age_statsd':
        ensure             => 'present',
        user               => 'thumbor',
        description        => 'generate thumbor age metrics',
        command            => '/usr/local/bin/generate-thumbor-age-metrics-nc.sh',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '1m'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    # create a list of installed fonts - T280718

    $fc_list_dir = '/srv/fc-list'
    $fc_list_file = "${fc_list_dir}/fc-list"
    $fc_list_cmd = '/usr/bin/fc-list :fontformat=TrueType'

    file { $fc_list_dir:
        ensure => directory,
    }

    file { '/usr/local/bin/fc-list-dump.sh':
        ensure  => present,
        mode    => '0555',
        content => "#!/bin/bash\n/${fc_list_cmd} | /usr/bin/sort 1> ${fc_list_file} 2> ${fc_list_file}.err",
        require => File[$fc_list_dir],
    }

    systemd::timer::job { 'fc-list-dump':
        description     => 'Write the output of the fc-list command to a file',
        command         => '/usr/local/bin/fc-list-dump.sh',
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '1d',
        },
        user            => 'root',
        logging_enabled => false,
    }
}
