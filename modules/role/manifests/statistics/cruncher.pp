# (stat1003 / stat1006)
class role::statistics::cruncher inherits role::statistics::base {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    backup::set { 'home' : }

    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # rsync logs from logging hosts
    include ::statistics::rsync::eventlogging

    # Reportupdater jobs that get data from MySQL analytics slaves
    include ::profile::reportupdater::jobs::mysql

    # Geowiki jobs that get data from MySQL analytics slave and save the data
    # in a private locally hosted git repository.
    include ::profile::geowiki
}
