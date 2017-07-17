# (stat1003)
class role::statistics::cruncher {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::profile::statistics::cruncher

    # will be removed as part of T152712
    if $::hostname == 'stat1003' {
        # Reportupdater jobs that get data from MySQL analytics slaves
        include ::profile::reportupdater::jobs::mysql

    }
    # else moved to stat1006
    else {
        # Geowiki jobs that get data from MySQL analytics slave and save the data
        # in a private locally hosted git repository.
        include ::profile::geowiki
    }
}
