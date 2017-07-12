# == Class role::statistics::cruncher_new
# TODO: rename to cruncher after stat1003 is gone.
# (stat1006)
class role::statistics::cruncher_new {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::profile::statistics::cruncher

    # TODO: include these.

    # Reportupdater jobs that get data from MySQL analytics slaves
    # include ::profile::reportupdater::jobs::mysql

    # Geowiki jobs that get data from MySQL analytics slave and save the data
    # in a private locally hosted git repository.
    # include ::profile::geowiki
}
