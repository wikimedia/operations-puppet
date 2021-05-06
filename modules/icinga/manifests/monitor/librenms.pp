# == Class: icinga::monitor::librenms
#
# Included on the Icinga hosts to poll LibreNMS API and generate Icinga criticals.
class icinga::monitor::librenms {
    monitoring::service { 'librenms_alerts':
        ensure        => absent,
        check_command => 'check_librenms',
        description   => 'LibreNMS has a critical alert',
        notes_url     => 'https://bit.ly/wmf-librenms',
        critical      => true,
    }
}
