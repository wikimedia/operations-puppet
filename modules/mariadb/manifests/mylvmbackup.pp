# == Define mariadb::mylvmbackup
# Uses mylvmbackup to periodically rsync an LVM snapshot of the
# MariaDB data directory to a destination.
#
# == Parameters
#
# [*dest*]
#   Rsync destination of backup.
#
# [*vgname*]
#   Specifies the volume group of the logical volume where the MariaDB data
#   directory is located.  Default: $::hostname-vg
#
# [*lvname*]
#   Specifies the name of the logical volume where the MariaDB data directory is
#   located.  Default: mariadb
#
# [*mountdir*]
#   Path for mounting the snapshot volume to.
#   See: --mountdir option for mylvmbackup.
#   Default: /var/cache/mylvmbackup/mnt/${title}
#
# [*socket*]
#   Path to mariadb socket.  Default: /tmp/mysql.sock
#
# ...standard cron resource parameters...
#
# == Usage
#
# # Back up the MariaDB data directory to host.example.org every hour.
# mariadb::mylvmbackup { 'myinstance':
#   dest   => 'host.example.org::rsync_module/path/to/backups/'
#   minute => 0,
# }
#
define mariadb::mylvmbackup(
    $dest,
    $vgname   = "${::hostname}-vg",
    $lvname   = 'mariadb',
    $mountdir = "/var/cache/mylvmbackup/mnt/${title}",
    $socket   = '/tmp/mysql.sock',
    $hour     = undef,
    $minute   = undef,
    $month    = undef,
    $monthday = undef,
    $weekday  = undef,
    $ensure   = 'present'
)
{
    require_package('mylvmbackup')

    if !defined(File['/var/log/mylvmbackup']) {
        file { '/var/log/mylvmbackup':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }
    if !defined(Logrotate::Conf['mylvmbackup']) {
        logrotate::conf { 'mylvmbackup':
            ensure => $ensure,
            source => 'puppet:///modules/mariadb/mylvmbackup.logrotate',
        }
    }

    # The prebackup rsync hook for this mylvmbackup
    # job will be stored in this directory.
    $hooksdir = "/usr/share/mylvmbackup/${title}"
    file { $hooksdir:
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
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
        mode    => '0544',
        content => template('mariadb/mylvmbackup-prebackup.erb'),
        require => Package['mylvmbackup'],
    }

    # --backuptype none will mean no copy of the lvm snapshot will be made
    # by mylvmbackup.  Instead, this is handled by the prebackup hook,
    # which just rsyncs the lvm snapshot to a destination.
    # Use flock to make sure this only ever runs one mylvmbackup at a time.
    # PATH seems to be funky in flock subshell(?), and mylvmbackup runs
    # commands like lvm and mount unqualfied.  Reconstruct PATH inside
    # of the flock command appropriately.
    $command = "/usr/bin/flock -n /var/lock/mylvmbackup-${title} -c 'PATH=/usr/bin:/sbin:/bin /usr/bin/mylvmbackup --socket ${socket} --hooksdir ${hooksdir} --vgname ${vgname} --lvname ${lvname} --mountdir ${mountdir} --backuptype none'  >>/var/log/mylvmbackup/${title}.log 2>&1"
    cron { "mylvmbackup-${title}":
        ensure   => $ensure,
        command  => $command,
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => [
            Package['mylvmbackup'],
            File["${hooksdir}/preflush.pm"],
            File["${hooksdir}/prebackup"],
        ],
    }
}
