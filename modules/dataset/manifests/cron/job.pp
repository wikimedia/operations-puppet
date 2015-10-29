# == Define dataset::cron::pageviews
# Regularly copies over files with from $source to $destination.
# using the current definition of pageviews, from an rsyncable location.
#
define dataset::cron::job(
    $source,
    $destination,
    $user        = 'datasets',
    $mailto      = 'ops-dumps@wikimedia.org',
    $hour        = undef,
    $minute      = undef,
    $month       = undef,
    $monthday    = undef,
    $weekday     = undef,
    $ensure      = 'present',
)
{
    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    cron { "dataset-${title}":
        ensure      => $ensure,
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
