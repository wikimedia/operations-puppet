# == Class elasticsearch::nagios::cirrus_plugin
# Includes the cirrus specific checks for elasticsearch.
# include this class on your Nagios/Icinga node.
#
class icinga::elasticsearch::cirrus_plugin {
    file { '/usr/lib/nagios/plugins/check_cirrus_frozen_writes.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/elasticsearch/check_cirrus_frozen_writes.py',
    }
    require_package('python3-requests', 'python3-dateutil')
}
