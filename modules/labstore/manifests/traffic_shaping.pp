class labstore::traffic_shaping(
    String $nfs_write = '75mbps',
    String $nfs_read = '75mbps',
    String $nfs_dumps_read = '5000kbps',
    String $egress = '40000kbps',
    String $interface = $facts['networking']['primary'],
) {

    file { '/usr/local/sbin/tc-setup':
        ensure  => absent,
    }

    file { '/etc/network/if-up.d/tc':
        ensure  => absent,
    }

    file { '/etc/modprobe.d/options-ifb.conf':
        ensure  => absent,
    }

    file_line { 'enable_ifb':
        ensure => absent,
        line   => 'ifb',
        path   => '/etc/modules',
    }

    file_line { 'enable_act_mirred':
        ensure => absent,
        line   => 'act_mirred',
        path   => '/etc/modules',
    }
}
