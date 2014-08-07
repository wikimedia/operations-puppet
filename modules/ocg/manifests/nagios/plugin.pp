# == Class ocg::nagios::plugin
# Includes the check_ocg_health python script.
# include this class on your Nagios/Icinga node.
#
class ocg::nagios::plugin {
    file { '/usr/lib/nagios/plugins/check_ocg_health':
        source  => 'puppet:///modules/ocg/nagios/check_ocg_health',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['icinga'],
    }
}
