# (stat1002)
class role::statistics::private inherits role::statistics::base {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::statistics::private

    # Run Hadoop/Hive reportupdater jobs here.
    include ::profile::reportupdater::jobs::hadoop
}
