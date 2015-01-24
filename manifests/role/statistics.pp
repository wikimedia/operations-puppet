class role::statistics {
    # Manually set a list of statistics servers.
    $statistics_servers = [
        'stat1001.eqiad.wmnet',
        'stat1002.eqiad.wmnet',
        'stat1003.eqiad.wmnet',
        'analytics1027.eqiad.wmnet',
    ]

    # we are attempting to stop using /a and to start using
    # /srv instead.  stat1002 still use
    # /a by default.  # stat1001 and stat1003 use /srv.
    $working_path = $::hostname ? {
        'stat1001' => '/srv',
        'stat1003' => '/srv',
        default    => '/a',
    }

    class { '::statistics':
        servers      => $statistics_servers,
        working_path => $working_path,
    }
}


# (stat1003)
class role::statistics::cruncher inherits role::statistics {
    system::role { 'role::statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include role::backup::host
    backup::set { 'home' : }

    # include stuff common to statistics compute nodes
    include statistics::compute

    # Aaron Halfaker (halfak) wants MongoDB for his project.
    class { 'mongodb':
        dbpath  => "${::statistics::working_path}/mongodb",
    }

    # rsync logs from logging hosts
    include statistics::rsync::eventlogging


    # geowiki: bringing data from production slave db to research db
    include geowiki::job::data
     # geowiki: generate limn files from research db and push them
    include geowiki::job::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include geowiki::job::monitoring


    # Use the statistics::limn::data::generate define
    # to set up cron jobs to generate and generate limn files
    # from research db and push them
    statistics::limn::data::generate { 'mobile':    }
    statistics::limn::data::generate { 'flow':      }
    statistics::limn::data::generate { 'edit':      }
    statistics::limn::data::generate { 'language':  }

    include statistics::cron_blog_pageviews
}


# (stat1002)
class role::statistics::private inherits role::statistics {
    system::role { 'role::statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include role::backup::host
    backup::set { 'home' : }

    # include stuff common to statistics compute nodes
    include statistics::compute

    # wikistats code is run here to
    # generate stats.wikimedia.org data
    include statistics::wikistats

    # rsync logs from logging hosts
    include statistics::rsync::webrequest

    # eventlogging logs are not private, but they
    # are here for convenience
    include statistics::rsync::eventlogging
    # backup eventlogging logs
    backup::set { 'a-eventlogging' : }

    # kafkatee is useful here for adhoc processing of kafkadata
    require_package('kafkatee')

    # aggregating hourly webstatscollector project count files into
    # daily per site csvs.
    # Although it is in the “private” role, the dataset actually isn't
    # private. We just keep it here to spare adding a separate role.
    include statistics::aggregator
}


# (stat1001)
class role::statistics::web inherits role::statistics {
    system::role { 'role::statistics::web':
        description => 'Statistics private data host and general compute node'
    }

    # include stuff common to statistics webserver nodes.
    include statistics::web

    # # include statistics web sites
    include statistics::sites::datasets
    include statistics::sites::metrics
    include statistics::sites::stats
}

