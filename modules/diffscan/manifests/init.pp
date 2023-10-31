# SPDX-License-Identifier: Apache-2.0
# == Class: diffscan
#
# This class installs & manages diffscan,
# an nmap wrapper for differential port scans.
# See https://github.com/ameihm0912/diffscan2
#
# == Parameters
#
# [*base_dir*]
#   The working directory to use
#   Defaults to "/srv/diffscan".
#
class diffscan(
    Stdlib::Unixpath $base_dir  = '/srv/diffscan',
) {
    ensure_packages(['nmap'])

    file { $base_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/usr/local/sbin/diffscan':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/diffscan/diffscan.py',
    }
}
