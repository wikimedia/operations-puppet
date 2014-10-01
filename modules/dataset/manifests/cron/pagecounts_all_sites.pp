# == Class dataset::cron::pagecounts_all_sites
# Copies over the webstats/ files (AKA pagecounts_all_sites)
# from an rsyncable location.
#
# These *-all-sites datasets recreates the webstatscollector
# logic in Hadoop and Hive, except that this dataset includes
# requests to mobile and zero sites.
#
# See: https://github.com/wikimedia/analytics-refinery/tree/master/oozie/webstats.
#      https://wikitech.wikimedia.org/wiki/Analytics/Pagecounts-all-sites
#
class dataset::cron::pagecounts_all_sites(
    $source,
    $enable      = true,
    $destination = '/data/xmldatadumps/public/other/pagecounts-all-sites',
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

    cron { 'pagecounts-all-sites':
        ensure      => $ensure,
        command     => "/usr/bin/rsync -rt --delete --chmod=go-w ${source}/ ${destination}/",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '51',
        require     => User[$user],
    }
}
