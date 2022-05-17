# SPDX-License-Identifier: Apache-2.0
# == Class: diffscan
#
# This class installs & manages diffscan,
# an nmap wrapper for differential port scans.
# See https://github.com/ameihm0912/diffscan2
#
# == Parameters
#
# [*ipranges*]
#   The list of IP/masks to scan. See nmap doc for accepted formats.
#
# [*emailto*]
#   Diff emails recipient. Defaults to "root".
#
# [*groupname*]
#   An identifier to distinguish between several instances.
#   Defaults to "default".
#
# [*base_dir*]
#   The working directory to use
#   Defaults to "default".
#
class diffscan(
    Array[Stdlib::IP::Address] $ipranges  = [],
    String                     $emailto   = '',
    String                     $groupname = 'default',
    Stdlib::Unixpath           $base_dir  = '/srv/diffscan',
) {
    ensure_packages(['nmap'])

    file { $base_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }
    file { "${base_dir}/targets-${groupname}.txt":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('diffscan/targets.txt.erb'),
    }
    file { '/usr/local/sbin/diffscan':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/diffscan/diffscan.py',
    }
    $command = "/usr/local/sbin/diffscan -p 1-65535 -E ${emailto} -W ${base_dir} ${base_dir}/targets-${groupname}.txt"
    systemd::timer::job {"diffscan-${groupname}":
        user        => 'root',
        description => "Daily diffscan for ${groupname}",
        command     => $command,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00:00:00',  # Every day at 12:00
        },
    }
}
