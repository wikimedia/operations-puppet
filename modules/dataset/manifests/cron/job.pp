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
        command     => "/usr/bin/rsync -rt --delete --chmod=go-w ${source}/ ${destination}/",
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
