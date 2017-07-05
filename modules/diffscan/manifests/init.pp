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
#   Defaults to "diffscan".
#
class diffscan(
    $ipranges={},
    $emailto='root@wikimedia.org',
    $groupname='diffscan'
) {
    file { '/srv/diffscan':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }
    file { "/srv/diffscan/targets-${groupname}.txt":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('diffscan/targets.txt.erb'),
    }
    file { '/srv/diffscan/diffscan.py':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0554',
        source => 'puppet:///modules/diffscan/diffscanpy',
    }
    cron { "diffscan-${groupname}":
        ensure  => present,
        user    => 'root',  # nmap needs root privileges
        command => "/srv/diffscan/diffscan.py targets-${groupname}.txt ${emailto} ${groupname}",
        hour    => '0',
    }

}
