# role classes for dataset servers

class role::dataset::pagecountsraw($enable = true) {
    class { '::dataset::cron::pagecountsraw':
        enable  => $enable,
        source  => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-raw/*/*/',
    }
}

# == Class role::dataset::pagecounts_all_sites
#
# NOTE: this requires that an rsync server
# module named 'hdfs-archive' is configured on stat1002.
#
# This will make these files available at
# http://dumps.wikimedia.org/other/pagecounts-all-sites/
#
class role::dataset::pagecounts_all_sites($enable = true) {
    # TODO: Make this class use dataset::cron::job define instead.
    class { '::dataset::cron::pagecounts_all_sites':
        source =>  'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-all-sites',
        enable => $enable,
    }
}

# == Class role::dataset::pageviews
#
# NOTE: this requires that an rsync server
# module named 'hdfs-archive' is configured on stat1002.
#
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
class role::dataset::pageviews($ensure = 'present') {
    # Note:  pageview and projectvew files are expected to be in the same
    # directory on dumps.wikimedia.org.  Here the destination for these
    # is the same.
    dataset::cron::job { 'pageview':
        ensure      => $ensure,
        source      => 'stat1002.eqiad.wmnet::hdfs-archive/{pageview,projectview}/legacy/hourly',
        destination => '/data/xmldatadumps/public/other/pageviews',
        minute      => '51',
    }
}

# == Class role::dataset::mediacounts
#
# NOTE: this requires that an rsync server
# module named 'hdfs-archive' is configured on stat1002.
#
# This will make these files available at
# http://dumps.wikimedia.org/other/mediacounts/
#
class role::dataset::mediacounts($enable = true) {
    class { '::dataset::cron::mediacounts':
        source =>  'stat1002.eqiad.wmnet::hdfs-archive/mediacounts',
        enable => $enable,
    }
}


# a dumps primary server has dumps generated on this host; other directories
# of content may or may not be generated here (but should all be eventually)
# mirrors to the public should not be provided from here via rsync
class role::dataset::primary {
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
    class { 'role::dataset::pagecountsraw': enable => true }

    class { 'role::dataset::pagecounts_all_sites':
        enable => true,
    }

    class { 'role::dataset::pageviews': }

    class { 'role::dataset::mediacounts':
        enable => true,
    }
}

# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    $rsync = {
        'public' => true,
        'peers'  => true,
    }
    $uploads = {
#        'pagecounts' => true,
#        'phab'       => true,
    }
    $grabs = {
#        'kiwix' => true,
    }
    class { 'dataset':
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }
    class { 'role::dataset::pagecountsraw': enable => false }
}
