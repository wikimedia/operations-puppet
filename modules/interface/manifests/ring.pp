# Definition: interface::ring
#
# Sets interface ring parameters (with ethtool)
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $setting:
#   The ring to resize (tx, rx, rx-mini, rx-jumbo)
# - $value:
#   The new ring size
#
# Note this doesn't check/set at runtime, because at least with
#  some drivers that restarts the interface and causes some traffic loss
define interface::ring($setting, $value, $interface='eth0') {
    # Set in /etc/network/interfaces
    interface::setting { $title: interface => $interface, setting => "hardware-dma-ring-${setting}", value => $value }

    # Change setting manually if Augeas made a real change
    exec { "ethtool ${interface} -g ${setting} ${value}":
        path        => '/usr/bin:/usr/sbin:/bin:/sbin',
        command     => "ethtool -G ${interface} ${setting} ${value}",
        subscribe   => Augeas["${interface}_${title}"],
        refreshonly => true,
        require     => Package['ethtool'],
    }
}
