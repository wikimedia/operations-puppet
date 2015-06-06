# == Class: wdqs::monitor::updater
#
# Create diamond monitoring for Updater tool
#
class wdqs::monitor::updater(
    $package_dir=$::wdqs::package_dir,
    $username=$::wdqs::username,
    ) {
    require ::wdqs::updater
    diamond::collector { 'WDQSUpdater':
        settings => {
            runner    => "${package_dir}/jolokia.sh",
            counters  => [
                '"updates/MeanRate"',
                '"batch-progress/MeanRate"',
            ],
            sudo_user => $username,
            interval  => 300,
        },
        source   => 'puppet:///modules/wdqs/WDQSUpdaterCollector.py',
    }

    sudo::user { 'diamond_to_blazegraph':
        user       => 'diamond',
        privileges => [
            "ALL=(${username}) NOPASSWD: ${package_dir}/jolokia.sh"
        ],
    }

}
