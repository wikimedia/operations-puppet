# SPDX-License-Identifier: Apache-2.0
# == Class: haproxykafka
#
# Install haproxykafka, dependencies and service files
#
# [*ensure*]
#   present or absent.
#
# [*config*]
#   Haproxykafka::Config struct used to build the actual configuration.
#
# [*user*]
#   The user to run haproxykafka, created as system user by puppet. The same
#   value is also used to create a system group and set permissions on files
#   and directories.
#   Defaults to haproxykafka.
#

class haproxykafka (
    Wmflib::Ensure       $ensure,
    Haproxykafka::Config $config,
    String               $user = 'haproxykafka',
) {
    package { 'haproxykafka':
        ensure => $ensure,
    }

    user { $user:
        ensure => $ensure,
        shell  => '/bin/false',
        home   => '/nonexistent',
        system => true,
    }

    $socketdir = '/var/run/haproxykafka'

    # TODO: from param/hiera
    file { $socketdir:
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $user,
        mode   => '0755',
        force  => true,
    }

    $confdir = '/etc/haproxykafka'
    $conffile = 'config.yaml'
    $conffile_full_path = "${confdir}/${conffile}"

    file { $confdir:
        ensure => stdlib::ensure($ensure, 'directory'),
        force  => true,
    }

    file { $conffile_full_path:
        ensure  => $ensure,
        owner   => $user,
        mode    => '0444',
        content => to_yaml($config),
        require => [File[$confdir], Package['haproxykafka']],
    }

    systemd::service { 'haproxykafka':
        ensure   => $ensure,
        restart  => true,
        override => true,
        content  => init_template('haproxykafka', 'systemd_override'),
        require  => File[$conffile_full_path],
    }
}
