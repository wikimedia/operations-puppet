# == Class dataset::cron::pageviews
# Copies over files with pageview statistics per page and project,
# using the current definition of pageviews, from an rsyncable location.
#
# These statistics are computed from the raw webrequest logs by the
# pageview definition: https://meta.wikimedia.org/wiki/Research:Page_view
#
# See: https://github.com/wikimedia/analytics-refinery/tree/master/oozie/pageview
#           (docs on the jobs that create the table and archive the files)
#      https://wikitech.wikimedia.org/wiki/Analytics/Data/Pageview_hourly
#           (docs on the table from which these statistics are computed)
#
class dataset::cron::pageviews(
    $source,
    $enable      = true,
    $destination = '/data/xmldatadumps/public/other/pageviews',
    $user        = 'datasets',
)
{
    $ensure = $enable ? {
        true    => 'present',
        default => 'absent',
    }

    file { $destination:
        ensure => 'directory',
        owner  => $user,
        group  => 'root',
    }

    cron { 'pageviews':
        ensure      => $ensure,
        command     => "/usr/bin/rsync -rt --delete --chmod=go-w ${source}/ ${destination}/",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '51',
        require     => User[$user],
    }
}
