# == Class udp2log::monitoring
# Includes scripts
# needed for udp2log monitoring.
#
class udp2log::monitoring {
    Class['udp2log'] -> Class['udp2log::monitoring']

    require_package('ganglia-logtailer')

    file { 'check_udp2log_log_age':
        path   => '/usr/lib/nagios/plugins/check_udp2log_log_age',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/icinga/check_udp2log_log_age',
    }

    file { 'check_udp2log_procs':
        path   => '/usr/lib/nagios/plugins/check_udp2log_procs',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/icinga/check_udp2log_procs',
    }

    file { 'rolematcher.py':
        path   => '/usr/share/ganglia-logtailer/rolematcher.py',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/rolematcher.py',
    }

    file { 'PacketLossLogtailer.py':
        path   => '/usr/share/ganglia-logtailer/PacketLossLogtailer.py',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/PacketLossLogtailer.py',
    }

    # send udp2log socket stats to ganglia.
    # include general UDP statistic monitoring.
    ganglia::plugin::python{ ['udp_stats', 'udp2log_socket']: }
}
