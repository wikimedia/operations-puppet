# == Define mysql_wmf::backupex::job
# Installs a cron job to periodically run mysql-backupex
# to take incremental backups using innobackupex.
#
# == Usage
#
# Install a cron job to run daily incremental innobackupex jobs
# using the mysql-backupex wrapper script
# using --parallel 2:
#
# mysql_wmf::backupex::job { 'mybackup':
#   basedir  => '/srv/backups/mysql/mybackup'
#   parallel => 2,
#   hour     => 4,
# }
#
#
# == Parameters
# [*basedir*]
#   Path in which innobackuped will take regular backups
#
# [*parallelism*]
#   Default: 1
#
# [*password_file*]
#   A my.cnf file containing user credentials for innobackupex to access MySQL.
#   Default: undef
#
define mysql_wmf::backupex::job (
    $basedir,
    $parallel      = 1,
    $password_file = undef,
    $hour          = undef,
    $minute        = undef,
    $month         = undef,
    $monthday      = undef,
    $weekday       = undef,
    $ensure        = 'present',
)
{
    require ::mysql_wmf::backupex

    $backupex_command = $password_file ? {
        undef   => "/usr/local/bin/mysql-backupex -P ${parallel} ${backup_path} 2>&1 >> /var/log/mysql-backupex/${title}.log",
        default => "/usr/local/bin/mysql-backupex -P ${parallel} -p ${password_file} ${backup_path} 2>&1 >> /var/log/mysql-backupex/${title}.log",
    }

    cron { "mysql-backupex-${title}":
        ensure   => $ensure
        command  => $backupex_command,
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
    }
}
