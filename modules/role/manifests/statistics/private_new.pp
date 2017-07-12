# == Class role::statistics::cruncher_new
# TODO: rename to private after stat1002 is gone.
# (stat1005)
class role::statistics::private_new {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::statistics::private

    # Run Hadoop/Hive reportupdater jobs here.
    # include ::profile::reportupdater::jobs::hadoop
}
