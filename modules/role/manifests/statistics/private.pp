# (stat1002 / stat1005)
class role::statistics::private {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::statistics::private

    # Run Hadoop/Hive reportupdater jobs here.
    include ::profile::reportupdater::jobs::hadoop
}
