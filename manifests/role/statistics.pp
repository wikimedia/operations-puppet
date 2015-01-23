# statistics servers (per ezachte - RT 2162)

class role::statistics {
    # include misc::statistics::user
    # include misc::statistics::base
    #
    # package { 'emacs23':
    #     ensure => 'installed',
    # }
    #
    # include role::backup::host
    # backup::set { 'home' : }
}

class role::statistics::www inherits role::statistics {
    # system::role { 'role::statistics':
    #     description => 'statistics web server',
    # }
    #
    # $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '365')
    #
    # include misc::statistics::webserver

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


# ------------------------------------------------------------ #
# The following role classes have commented out includes.
# These will be uncommented piecemeal while the above role
# have includes removed and are deprecated.


# == Class role::statistics::module
# Temp role to use the new statsitics module.
# The following roles will replace the above ones.
# When this happens the '::module' part of the class
# names will be removed.
class role::statistics::module {
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

class role::statistics::cruncher inherits role::statistics::module {
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

    # TODO:  Move geowiki into its own module:
    # geowiki: bringing data from production slave db to research db
    include misc::statistics::geowiki::jobs::data
    # geowiki: generate limn files from research db and push them
    include misc::statistics::geowiki::jobs::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include misc::statistics::geowiki::jobs::monitoring
}

class role::statistics::private inherits role::statistics::module {
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
    include misc::statistics::aggregator
}


class role::statistics::module::web inherits role::statistics::module {
    system::role { 'role::statistics::web':
        description => 'Statistics private data host and general compute node'
    }

    # include stuff common to statistics webserver nodes.
    include statistics::web

    # # include statistics web sites
    # include statistics::sites::datasets
    # include statistics::sites::metrics
    # include statistics::sites::reportcard
    # include statistics::sites::stats
}

