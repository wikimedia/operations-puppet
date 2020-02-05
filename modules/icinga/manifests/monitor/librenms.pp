# == Class: icinga::monitor::librenms
#
# Included on the Icinga hosts to poll LibreNMS API and generate Icinga criticals.
class icinga::monitor::librenms {
    monitoring::service { 'librenms_alerts':
        check_command => 'check_librenms',
        description   => 'LibreNMS has a critical alert',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#LibreNMS_alerts',
        critical      => true,
    }
}
