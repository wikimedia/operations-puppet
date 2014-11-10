# statistics servers (per ezachte - RT 2162)

class role::statistics {
    include misc::statistics::user
    include misc::statistics::base

    package { 'emacs23':
        ensure => 'installed',
    }

    include role::backup::host
    backup::set { 'home' : }
}

class role::statistics::cruncher inherits role::statistics {
    system::role { 'role::statistics':
        description => 'statistics number crunching server',
    }

    # include classes needed for crunching data on stat1003.
    include geoip
    include misc::statistics::dataset_mount
    include misc::statistics::mediawiki
    include misc::statistics::plotting
    include misc::statistics::packages::utilities
    # Aaron Halfaker (halfak) wants MongoDB for his project.
    include misc::statistics::db::mongo
    # Aaron Halfaker (halfak) wants python{,3}-dev environments for module
    # oursql
    include misc::statistics::dev
    include misc::udp2log::udp_filter
    include misc::statistics::rsync::jobs::eventlogging
    # geowiki: bringing data from production slave db to research db
    include misc::statistics::geowiki::jobs::data
    # geowiki: generate limn files from research db and push them
    include misc::statistics::geowiki::jobs::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include misc::statistics::geowiki::jobs::monitoring
}

class role::statistics::www inherits role::statistics {
    system::role { 'role::statistics':
        description => 'statistics web server',
    }

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')

    include misc::statistics::webserver
    # stats.wikimedia.org
    include misc::statistics::sites::stats
    # metrics.wikimedia,.org and metrics-api.wikimedia.org
    include misc::statistics::sites::metrics
    # reportcard.wikimedia.org
    include misc::statistics::sites::reportcard
    # default public file vhost
    # This default site get's used for example for public datasets at
    #   http://datasets.wikimedia.org/public-datasets/
    include misc::statistics::sites::datasets
    # rsync public datasets from stat1003 hourly
    include misc::statistics::public_datasets
}

class role::statistics::private inherits role::statistics {
    system::role { 'role::statistics':
        description => 'statistics private data host'
    }

    # include classes needed for crunching private data on stat1002
    include geoip
    include misc::statistics::dataset_mount
    include misc::statistics::mediawiki
    include misc::statistics::plotting
    include misc::statistics::packages::utilities
    include misc::udp2log::udp_filter
    # rsync logs from logging hosts
    # wikistats code is run here to
    # generate stats.wikimedia.org data
    include misc::statistics::wikistats
    include misc::statistics::packages::java
    include misc::statistics::rsync::jobs::webrequest
    include misc::statistics::rsync::jobs::eventlogging

    # kafkatee is useful here for adhoc processing of kafkadata
    require_package('kafkatee')

    # aggregating hourly webstatscollector project count files into
    # daily per site csvs.
    # Although it is in the “private” role, the dataset actually isn't
    # private. We just keep it here to spare adding a separate role.
    include misc::statistics::aggregator::projectcounts

    # backup eventlogging logs
    backup::set { 'a-eventlogging' : }
}
