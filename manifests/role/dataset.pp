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
        source => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-raw/*/*/',
    }

    # This will make these files available at
    # http://dumps.wikimedia.org/other/pagecounts-all-sites/
    class { '::dataset::cron::pagecounts_all_sites':
        source => 'stat1002.eqiad.wmnet::hdfs-archive/pagecounts-all-sites',
    }
    
    # This will make these files available at
    # http://dumps.wikimedia.org/other/mediacounts/
    class { '::dataset::cron::mediacounts':
        source => 'stat1002.eqiad.wmnet::hdfs-archive/mediacounts',
    }
}

# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    system::role { 'role::dataset::secondary':
        description => 'dataset secondary host',
    }

    $rsync = {
        'public' => true,
        'peers'  => true,
    }
    $grabs = {
    }
    $uploads = {
    }

    class { 'dataset':
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }
}
