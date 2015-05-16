# Set up neutron on a compute node
class openstack::neutron::compute(
    $neutronconfig,
    $data_interface_ip,
    $openstack_version=$::openstack::version,
    ) {
    sysctl::parameters { 'openstack':
        values   => {
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,
        },
        priority => 50,
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    package { 'openvswitch-datapath-dkms':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    service { 'openvswitch-switch':
        ensure  => 'running',
        require => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    service { 'neutron-plugin-openvswitch-agent':
        ensure  => 'running',
        require => Package['neutron-plugin-openvswitch-agent', 'openvswitch-datapath-dkms'],
    }

    exec { 'create_br-int':
        unless  => '/usr/bin/ovs-vsctl br-exists br-int',
        command => '/usr/bin/ovs-vsctl add-br br-int',
        require => Service['openvswitch-switch'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        require => Package['neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-plugin-openvswitch-agent'],
        require => Package['neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }
}
