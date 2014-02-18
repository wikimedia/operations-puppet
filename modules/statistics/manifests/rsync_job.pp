# Define: statistics::rsync_job
#
# Sets up a daily cron job to rsync from $source to $destination
# as the $misc::statistics::user::username user.  This requires
# that the $misc::statistics::user::username user is installed
# on both $source and $destination hosts.
#
# Parameters:
#    source      - rsync source argument (including hostname)
#    destination - rsync destination argument
#
define statistics::rsync_job($source, $destination) {
    require statistics::user

    # ensure that the destination directory exists
    file { $destination:
        ensure  => 'directory',
        owner   => $statistics::user::username,
        group   => 'wikidev',
        mode    => '0775',
    }

    # Create a daily cron job to rsync $source to $destination.
    # This requires that the $statistics::user::username
    # user is installed on the source host.
    cron { "rsync_${name}_logs":
        command => "/usr/bin/rsync -rt ${source} ${destination}/",
        user    => $statistics::user::username,
        hour    => 8,
        minute  => 0,
    }
}

