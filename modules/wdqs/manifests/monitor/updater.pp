# == Class: wdqs::monitor::updater
#
# Create diamond monitoring for Updater tool
#
class wdqs::monitor::updater(
$package_dir,
$username
) {
    diamond::collector { 'WDQSUpdater':
        settings => {
            runner => "$package_dir/jolokia.sh",
            counters => [
                '"updates/MeanRate"',
                '"batch-progress/MeanRate"',
            ],
        },
        source => 'puppet:///modules/wdqs/WDQSUpdaterCollector.py',
    }
    
    sudo::user { 'diamond_to_blazegraph':
        user => 'diamond',
        privileges => [
            "ALL=($username) NOPASSWD: $package_dir/jolokia.sh"
        ],
    }
    
}

