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
        ensure => absent,
    }
}
