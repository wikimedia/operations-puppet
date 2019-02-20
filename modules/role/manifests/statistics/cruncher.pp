class role::statistics::cruncher {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::standard
    include ::profile::base::firewall

    include ::profile::statistics::cruncher

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    # Reportupdater jobs that get data from MySQL analytics slaves
    include ::profile::reportupdater::jobs::mysql
}
