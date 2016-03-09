# role classes for dataset servers

# a dumps primary server has dumps generated on this host; other directories
# of content may or may not be generated here (but should all be eventually)
# mirrors to the public should not be provided from here via rsync
class role::dataset::primary {
    system::role { 'role::dataset::primary':
        description => 'dataset primary host',
    }

    $rsync = {
        'public' => true,
        'peers'  => true,
        'labs'   => true,
    }
    $grabs = {
        'kiwix' => true,
    }
    $uploads = {
        'pagecounts' => true,
        'phab'       => true,
    }
    class { 'dataset':
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }

    # NOTE: these requires that an rsync server module named 'hdfs-archive' is
    # configured on stat1002.
    class { '::dataset::cron::pagecountsraw':
        enable => true,
        source => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-raw/*/*/',
    }

    # Copies over the mediacounts files
    # from an rsyncable location.
    dataset::cron::job { 'mediacounts':
        ensure      => present,
        source      => 'stat1002.eqiad.wmnet::hdfs-archive/mediacounts',
        destination => '/data/xmldatadumps/public/other/mediacounts',
        minute      => '41',
    }

    # Copies over the webstats/ files (AKA pagecounts_all_sites)
    # from an rsyncable location.
    #
    # These *-all-sites datasets recreates the webstatscollector
    # logic in Hadoop and Hive, except that this dataset includes
    # requests to mobile and zero sites.
    #
    # See: https://github.com/wikimedia/analytics-refinery/tree/master/oozie/webstats.
    #      https://wikitech.wikimedia.org/wiki/Analytics/Pagecounts-all-sites
    dataset::cron::job { 'pagecounts_all_sites':
        ensure      => present,
        source      => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-all-sites',
        destination => '/data/xmldatadumps/public/other/pagecounts-all-sites',
        minute      => '51',
    }

    class { '::dataset::cron::rsync::nginxlogs':
        enable => true,
        dest   => 'stat1002.eqiad.wmnet::srv/log/webrequest/archive/dumps.wikimedia.org/',
    }

    class { '::dataset::cron::wikitech_dumps':
        enable => true,
        url    => 'https://wikitech.wikimedia.org/dumps/',
    }

    # This will make these files available at
    # http://dumps.wikimedia.org/other/pageviews/
    #
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
    # Note:  pageview and projectvew files are expected to be in the same
    # directory on dumps.wikimedia.org.  Here the destination for these
    # is the same.
    dataset::cron::job { 'pageview':
        ensure      => present,
        source      => 'stat1002.eqiad.wmnet::hdfs-archive/{pageview,projectview}/legacy/hourly',
        destination => '/data/xmldatadumps/public/other/pageviews',
        minute      => '51',
    }
}

