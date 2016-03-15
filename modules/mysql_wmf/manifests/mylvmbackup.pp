# == Define mysql_wmf::mylvmbackup
# Uses mylvmbackup to periodically rsync an LVM snapshot of the
# MySQL data directory to a destination.
#
# == Parameters
#
# [*dest*]
#   Rsync destination of backup.
#
# [*vgname*]
#   Specifies the volume group of the logical volume where the MySQL data
#   directory is located.  Default: $::hostname-vg
#
# [*lvname*]
#   Specifies the name of the logical volume where the MySQL data directory is
#   located.  Default: mysql
#
# [*mountdir*]
#   Path for mounting the snapshot volume to.
#   See: --mountdir option for mylvmbackup.
#   Default: /var/cache/mylvmbackup/mnt/${title}
#
# ...standard cron resource parameters...
#
# == Usage
#
# # Back up the mysql data directory to host.example.org every hour.
# mysql_wmf::mylvmbackup { 'myinstance':
#   dest   => 'host.example.org::rsync_module/path/to/backups/'
#   minute => 0,
# }
#
define mysql_wmf::mylvmbackup(
    $dest,
    $vgname   = "${::hostname}-vg",
    $lvname   = 'mysql',
    $mountdir = "/var/cache/mylvmbackup/mnt/${title}",
    $hour     = undef,
    $minute   = undef,
    $month    = undef,
    $monthday = undef,
    $weekday  = undef,
    $ensure   = 'present'
)
{
    require_package('mylvmbackup')

    # The prebackup rsync hook for this mylvmbackup
    # job will be stored in this directory.
    $hooksdir = "/usr/share/mylvmbackup/${title}"
    file { $hooksdir:
        ensure => ensure_directory($ensure)
        owner  => 'root',
        group  => 'root',
        mode   => 0555,
    }
    # Always use the preflush.pm that ships with mylvmbackup
    file { "${hooksdir}/preflush.pm":
        ensure  => ensure_link($ensure),
        target  => '/usr/share/mylvmbackup/preflush.pm',
        require => Package['mylvmbackup'],
    }

    # prebackup rsyncs the LVM snapshot to $dest.
    file { "${hooksdir}/prebackup":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => 0444,
        content => template('mysql_wmf/mylvmbackup-prebackup.erb'),
        require => Package['mylvmbackup'],
    }

    # --backuptype none will mean no copy of the lvm snapshot will be made
    # by mylvmbackup.  Instead, this is handled by the prebackup hook,
    # which just rsyncs the lvm snapshot to a destination.
    $command = "/usr/bin/mylvmbackup --hooksdir ${hooksdir} --vgname ${vgname} --lvname ${lvname} --backuptype none",
    cron { "mylvmbackup-${title}":
        ensure   => $ensure,
        command  => $command,
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => File["/usr/share/mylvmbackup/$title/prebackup"],
    }
}
