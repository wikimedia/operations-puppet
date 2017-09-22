# == Define dumps::web::fetches
# Regularly copies files from $source to $destination.
#
define dumps::web::fetches(
    $source,
    $destination,
    $user        = undef,
    $mailto      = 'ops-dumps@wikimedia.org',
    $hour        = undef,
    $minute      = undef,
    $month       = undef,
    $monthday    = undef,
    $weekday     = undef,
) {
    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    cron { "dumps-fetch-${title}":
        ensure      => 'present',
        # Run command via bash instead of sh so that $source can be fancier
        # wildcards or globs (e.g. /path/to/{dir1,dir1}/ok/data/ )
        command     => "bash -c '/usr/bin/rsync -rt --delete --chmod=go-w ${source}/ ${destination}/'",
        environment => "MAILTO=${mailto}",
        user        => $user,
        require     => User[$user],
        minute      => $minute,
        hour        => $hour,
        month       => $month,
        monthday    => $monthday,
        weekday     => $weekday,
    }
}
