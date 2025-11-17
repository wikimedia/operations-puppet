# SPDX-License-Identifier: Apache-2.0
# == Class: garage
#
# Garage is an open-source distributed object storage service tailored
# for self-hosting. Its API is S3-compatible. See
# <https://garagehq.deuxfleurs.fr/> for details.
#
# === Parameters
#
# [*config*]
#   A hash of Garage configuration options.
#
# === Examples
#
#  class { '::garage':
#    config => {
#      metadata_dir => '/srv/garage/meta',
#      data_dir     => '/srv/garage/data',
#      db_engine    => 'sqlite',
#    },
#  }
#
class garage(
    Hash $config,
) {

    systemd::sysuser {'garage': }
    ensure_packages('garage')

    service { 'garage':
        ensure    => running,
        enable    => true,
        provider  => 'systemd',
        subscribe => [
            File['/etc/garage.toml'],
            Package['garage'],
        ],
    }

    file { '/etc/garage.toml':
        group   => 'garage',
        mode    => '0440',
        content => template('garage/garage.toml.erb'),
        notify  => Service['garage'],
        before  => Service['garage'],
    }

}
