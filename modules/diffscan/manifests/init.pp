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
    Array[Stdlib::IP::Address] $ipranges  = [],
    String                     $emailto   = '',
    String                     $groupname = 'diffscan-default'
) {
    require_package('nmap')

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
        source => 'puppet:///modules/diffscan/diffscan.py',
    }
    file { '/usr/local/sbin/diffscan':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/diffscan/diffscan3.py',
    }
    cron { "diffscan-${groupname}":
        ensure  => present,
        user    => 'root',  # nmap needs root privileges
        command => "cd /srv/diffscan/; /srv/diffscan/diffscan.py -p 1-65535 -q /srv/diffscan/targets-${groupname}.txt ${emailto} ${groupname}",
        hour    => '0',
    }
    $base_dir = '/srv/diffscan3/'
    file { $base_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }
    $command = "/usr/local/sbin/diffscan -p 1-65535 -E jbond@wikimedia.org -W ${base_dir} ${base_dir}/targets-${groupname}.txt"
    systemd::timer::job {"diffscan-${groupname}":
        user        => 'root',
        description => "Daily diffscan for ${groupname}",
        command     => $command,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 12:00:00',  # Every day at 12:00
        },
    }
}
