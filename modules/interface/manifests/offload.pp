# Definition: interface::offload
#
# Sets interface offload parameters (with ethtool)
#
# Parameters:
# - $interface:
#   The network interface to operate on
# - $setting:
#   The (abbreviated) offload setting, e.g. 'gro'
# - $value:
#   The value (on/off)
define interface::offload($interface, $setting, $value)  {
    # Set in /etc/network/interfaces
    interface::setting { $title:
        interface => $interface,
        setting   => "offload-${setting}",
        value     => $value,
    }

    # And make sure it's always active
    $long_param = $setting ? {
        'rx'  => 'rx-checksumming',
        'tx'  => 'tx-checksumming',
        'sg'  => 'scatter-gather',
        'tso' => 'tcp-segmentation-offload',
        'ufo' => 'udp-fragmentation-offload',
        'gso' => 'generic-segmentation-offload',
        'gro' => 'generic-receive-offload',
        'lro' => 'large-receive-offload',
    }

    exec { "ethtool ${interface} -K ${setting} ${value}":
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        command => "ethtool -K ${interface} ${setting} ${value}",
        unless  => "test $(ethtool -k ${interface} | awk '/${long_param}:/ { print \$2 }') = '${value}'",
        require => Package['ethtool'],
    }
}
