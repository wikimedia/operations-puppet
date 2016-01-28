# Definition: bacula::director::jobdefaults
#
# Create a jobdefaults definition
#
# Parameters:
#   $when
#       An already defined schedule to use
#   $pool
#       An already defined pool where backups will end up in
#   $type
#       Backup (default), Restore, Verify, Migrate, Copy
#   $accurate
#       yes, no (default). Whether the backup will accurately reflect the filesystem state
#   $spool_data
#       yes, no (default). Whether the storage daemon will spool data for this
#       pool (if possible)
#   $priority
#       An arbitrary number. Lower means more urgent
#
# Actions:
#       Will create a job defaults definition using the given defaults
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::director::jobdefaults { '1st-sat-mypool':
#           schedule    => '1st-Sat',
#           pool        => 'mypool',
#       }
define bacula::director::jobdefaults(
    $when,
    $pool,
    $type='Backup',
    $accurate='no',
    $spool_data='no',
    $priority='10',
) {
    file { "/etc/bacula/conf.d/jobdefaults-${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'bacula',
        mode    => '0440',
        content => template('bacula/bacula-dir-jobdefaults.erb'),
        notify  => Service['bacula-director'],
    }
}
