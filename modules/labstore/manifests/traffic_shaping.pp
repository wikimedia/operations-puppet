class labstore::traffic_shaping {

    file { '/usr/local/sbin/tc-setup':
        ensure => present,
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/labstore/tc-setup.sh',
    }

    # run when interfaces come up.
    file { '/etc/network/if-up.d/tc':
        ensure => 'link',
        target => '/usr/local/sbin/tc-setup',
    }

    # under systemd either /etc/modules or /etc/load-modules.d works
    # since labs still has precise instances this is applied
    # using the non-.d model since it is still effective and consistent
    file_line { 'enable_ifb':
        ensure => present,
        line   => 'ifb',
        path   => '/etc/modules',
    }

    file_line { 'enable_act_mirred':
        ensure => present,
        line   => 'act_mirred',
        path   => '/etc/modules',
    }

    # ifb by default creates 2 interfaces
    file { '/etc/modprobe.d/ifb.conf':
        ensure  => present,
        content => 'options ifb numifbs=1',
    }
}
