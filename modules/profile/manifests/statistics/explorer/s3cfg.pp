# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::s3cfg
#
# This class manages the generic s3cmd configuration shared across all
# team-specific S3 profiles on the stat (explorer) hosts.
#
class profile::statistics::explorer::s3cfg {
    ensure_packages(['s3cmd'])

    file { '/etc/s3cmd':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/s3cmd/cfg.d':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
}