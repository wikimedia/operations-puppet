# == Class icinga::elasticsearch::cirrus_settings_plugin
# Includes the cirrus specific checks for elasticsearch.

class icinga::elasticsearch::cirrus_settings_plugin {
    file { '/usr/lib/nagios/plugins/check_cirrus_settings.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/elasticsearch/check_cirrus_settings.py',
    }
    require_package('python3-requests', 'python3-yaml', 'python3-jsonpath-rw')
}