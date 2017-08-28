# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
# Note: this class references the main wdqs class. It is the responsibility of
# the caller to make sure that the main wdqs calss is instantiated or that the
# parameter $package_dir and $username are set on the wdqs::updater class.
#
class wdqs::updater(
    $options,
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
    $data_dir = $::wdqs::data_dir,
){

    systemd::unit { 'wdqs-updater':
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
    }
    service { 'wdqs-updater':
        ensure => 'running',
    }
}
