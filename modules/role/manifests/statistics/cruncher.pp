class role::statistics::cruncher {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::statistics::cruncher
    include ::profile::statistics::dataset_mount

    # Include analytics/refinery deployment target.
    include ::profile::analytics::refinery

    include ::profile::analytics::client::limits

    include ::profile::statistics::eventlogging_rsync
}
