# Set up neutron on a dedicated network node
class openstack::neutron::nethost(
    $openstack_version=$::openstack::version,
    $external_interface='eth0',
    $neutronconfig,
    $data_interface_ip
) {
    include openstack::repo

    package { 'neutron-dhcp-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-l3-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-metadata-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'openvswitch-datapath-dkms':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'dnsmasq':
        ensure  => 'present',
    }

    service { 'openvswitch-switch':
        ensure  => 'running',
        require => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-plugin-openvswitch-agent':
        ensure  => 'running',
        require => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-dhcp-agent':
        ensure  => 'running',
        require => Package['neutron-dhcp-agent'],
    }

    service { 'neutron-l3-agent':
        ensure  => 'running',
        require => Package['neutron-l3-agent'],
    }

    service { 'neutron-metadata-agent':
        ensure  => 'running',
        require => Package['neutron-metadata-agent'],
    }

    exec { 'create_br-int':
            unless  => '/usr/bin/ovs-vsctl br-exists br-int',
            command => '/usr/bin/ovs-vsctl add-br br-int',
            require => Service['openvswitch-switch'],
    }

    exec { 'create_br-ex':
            unless  => '/usr/bin/ovs-vsctl br-exists br-ex',
            command => '/usr/bin/ovs-vsctl add-br br-ex',
            require => Service['openvswitch-switch'],
            before  => Exec['add-port'],
    }


    exec { 'add-port':
            unless  => "/usr/bin/ovs-vsctl list-ports br-ex | /bin/grep ${external_interface}",
            command => "/usr/bin/ovs-vsctl add-port br-ex ${external_interface}",
            require => Service['openvswitch-switch'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/api-paste.ini':
        content => template("openstack/${$openstack_version}/neutron/api-paste.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        require => Package['neutron-dhcp-agent', 'neutron-l3-agent', 'neutron-metadata-agent', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    sysctl::parameters { 'openstack':
        values => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'             => 1,
            'net.ipv6.conf.all.forwarding'    => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'     => 0,
        },
    }
}
