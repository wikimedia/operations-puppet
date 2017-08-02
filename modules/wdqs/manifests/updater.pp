# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
class wdqs::updater(
    $options,
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
){

    # Blazegraph service
    systemd::unit { 'wdqs-blazupdateregraph':
        content => template('wdqs/wdqs-updater.systemd.erb'),
        require        => [ File['/etc/wdqs/updater-logs.xml'],
                            Service['wdqs-blazegraph'] ],
    }
}
