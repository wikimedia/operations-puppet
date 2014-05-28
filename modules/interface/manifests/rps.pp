# Definition: interface::rps
#
# Automagically sets RPS (and optionally, RSS) for an interface
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $rss_pattern:
#   Optional RSS IRQ name pattern
#   If set (to hw-specific value), RSS will be enabled as well
#   Must contain a single "%d" format character for the queue number
#   (on bnx2x, this would be "eth0-fp-%d")
define interface::rps( $rss_pattern="" ) {
    $interface = $title

    # Disable irqbalance if RSS in use
    if $rss_pattern != "" {
        require irqbalance::disable
    }

    file { '/usr/local/sbin/interface-rps':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/interface/interface-rps.py',
    }

    file { "/etc/init/enable-rps-$interface.conf":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('interface/enable-rps.conf.erb'),
    }

    exec { "interface-rps $interface":
        command   => "/usr/local/sbin/interface-rps $interface $rss_pattern",
        subscribe => File["/etc/init/enable-rps-$interface.conf"],
        require   => File["/etc/init/enable-rps-$interface.conf"],
    }
}
