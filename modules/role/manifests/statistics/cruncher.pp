# (stat1003)
class role::statistics::cruncher {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::profile::statistics::cruncher

    # Reportupdater jobs that get data from MySQL analytics slaves
    include ::profile::reportupdater::jobs::mysql

    # Geowiki jobs that get data from MySQL analytics slave and save the data
    # in a private locally hosted git repository.
    include ::profile::geowiki
}
