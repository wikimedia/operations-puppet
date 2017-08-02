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
){

    base::service_unit { 'wdqs-updater':
        template_name  => 'wdqs-updater',
        systemd        => systemd_template('wdqs-updater'),
        upstart        => upstart_template('wdqs-updater'),
        service_params => {
            enable => true,
        },
        require        => [ File['/etc/wdqs/updater-logs.xml'],
                            Service['wdqs-blazegraph'] ],
    }
}
