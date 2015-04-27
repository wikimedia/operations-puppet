# == Define: statistics::rsync_job
#
# Sets up a daily cron job to rsync from $source to $destination
# as the $misc::statistics::user::username user.  This requires
# that the $misc::statistics::user::username user is installed
# on both $source and $destination hosts.
#
# == Parameters:
#    source         - rsync source argument (including hostname)
#    destination    - rsync destination argument
#    retention_days - If set, a cron will be installed to remove files older than this many days from $destination.
#    ensure
#
define statistics::rsync_job($source, $destination, $retention_days = undef, $ensure = 'present') {
    Class['::statistics'] -> Statistics::Rsync_job[$name]
    require statistics::user

    # ensure that the destination directory exists
    file { $destination:
        ensure  => 'directory',
        owner   => $::statistics::user::username,
        group   => 'wikidev',
        mode    => '0755',
    }

    # Create a daily cron job to rsync $source to $destination.
    # This requires that the $misc::statistics::user::username
    # user is installed on the source host.
    cron { "rsync_${name}_logs":
        command => "/usr/bin/rsync -rt --perms --chmod=g-w ${source} ${destination}/",
        user    => $::statistics::user::username,
        hour    => 8,
        minute  => 0,
        ensure  => $ensure,
    }

    $prune_old_logs_ensure = $retention_days ? {
        undef   => 'absent',
        default => 'present',
    }

    cron { "prune_old_${name}_logs":
        ensure  => $prune_old_logs_ensure,
        command => "/usr/bin/find ${destination} -ctime +${retention_days} -exec rm {} \\;",
        user    => $::statistics::user::username,
        minute  => 0,
        hour    => 9,
    }
}
