# Definition: interface::rps
#
# Automagically sets RPS for an interface
#
# Parameters:
# - $interface:
#   The network interface to operate on
define interface::rps {
    $interface = $title

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
        content => tempate('interface/enable-rps.conf.erb'),
    }

    exec { "interface-rps $interface":
        command   => "/usr/local/sbin/interface-rps $interface",
        subscribe => File["/etc/init/enable-rps-$interface.conf"],
        require   => File["/etc/init/enable-rps-$interface.conf"],
    }
}
