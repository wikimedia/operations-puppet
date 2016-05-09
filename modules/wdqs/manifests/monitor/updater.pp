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
            counters => [
                '"updates/Count"',
                '"updates/MeanRate"',
                '"updates/OneMinuteRate"',
                '"batch-progress/Count"',
                '"batch-progress/MeanRate"',
                '"batch-progress/OneMinuteRate"',
            ],
        },
        source   => 'puppet:///modules/wdqs/monitor/wdqs_updater.py',
    }
}
