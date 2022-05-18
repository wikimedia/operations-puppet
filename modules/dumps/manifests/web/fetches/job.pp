# == Define dumps::web::fetches
# Regularly copies files from $source to $destination.
#
# == Parameters
#
# [*ensure*]
#   Ensure status of cron job. ensure => absent will not remove any existent data.
#
define dumps::web::fetches::job(
    $source,
    $destination,
    $delete      = true,
    $exclude     = undef,
    $user        = undef,
    $mailto      = 'ops-dumps@wikimedia.org',
    $hour        = '*',
    $minute      = '*',
    $month       = '*',
    $monthday    = '*',
    $weekday     = undef,
    $ensure      = 'present',
) {
    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    $delete_option = $delete ? {
        true    => '--delete',
        default => ''
    }

    $exclude_option = $exclude ? {
        undef   => '',
        default => " --exclude ${exclude}"
    }

    # The rsync options, and paths can be so complex to just parse to the systemd service, so
    # we'll need to wrap the command in a script, which the service can then run.
    file { "/usr/local/bin/dump-fetch-${title}.sh":
        ensure  => $ensure,
        owner   => $user,
        group   => 'root',
        mode    => '0554',
        content => template('dumps/rsync/run_rsync.erb'),
    }

    # Construct interval variable. The systemd calendar "parser" will complain about
    # * for weekdays.
    if ($weekday) {
        $interval = "${weekday} *-${month}-${monthday} ${hour}:${minute}:00"
    } else {
        $interval = "*-${month}-${monthday} ${hour}:${minute}:00"
    }

    systemd::timer::job { "dumps-fetch-${title}":
        ensure      => $ensure,
        description => "${title} rsync job",
        command     => "/usr/local/bin/dump-fetch-${title}.sh",
        user        => $user,
        environment => {'MAILTO' => $mailto},
        interval    => {'start' => 'OnCalendar', 'interval' => $interval},
    }
}
