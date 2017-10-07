# == Class udp2log::monitoring
# Includes scripts
# needed for udp2log monitoring.
#
class udp2log::monitoring {
    Class['udp2log'] -> Class['udp2log::monitoring']

    file { 'check_udp2log_log_age':
        path   => '/usr/lib/nagios/plugins/check_udp2log_log_age',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/udp2log/check_udp2log_log_age',
    }

    file { 'check_udp2log_procs':
        path   => '/usr/lib/nagios/plugins/check_udp2log_procs',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/udp2log/check_udp2log_procs',
    }
}
