# (stat1002 / stat1005)
class role::statistics::private {
    system::role { 'statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include ::profile::statistics::private

    # will be removed as part of T152712
    if $::hostname == 'stat1002' {
        # Run Hadoop/Hive reportupdater jobs here.
        include ::profile::reportupdater::jobs::hadoop
    }
}
