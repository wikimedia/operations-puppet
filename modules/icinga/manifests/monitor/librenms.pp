# == Class: icinga::monitor::librenms
#
# Included on the Icinga hosts to poll LibreNMS API and generate Icinga criticals.
class icinga::monitor::librenms {
    monitoring::service { 'librenms_alerts':
        check_command => 'check_librenms',
        description   => 'LibreNMS has a critical alert',
        notes_url     => 'https://docs.google.com/document/d/1SeXdegjsfL94R6XYB1I4Uv8yjCPH1tVXeL0taJF0NNs/preview#heading=h.qkfum7lgbdo5',
        critical      => true,
    }
}
