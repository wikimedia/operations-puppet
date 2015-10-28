# the networking part of openstack
# https://wiki.openstack.org/wiki/Neutron
#  Labs currently uses nova-network rather than Neutron,
#  but we hope to migrate to Neutron someday.  Meanwhile
#  this code is largely vestigial.
class openstack::neutron::controller(
    $neutronconfig,
    $data_interface_ip,
    $openstack_version = $::openstack::version,
    ) {
    package { 'neutron-server':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    service { 'neutron-server':
        ensure    => 'running',
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['neutron-server'],
    }

    file { '/etc/neutron/neutron.conf':
        content => template("openstack/${$openstack_version}/neutron/neutron.conf.erb"),
        owner   => 'neutron',
        group   => 'nogroup',
        notify  => Service['neutron-server'],
        require => Package['neutron-server'],
        mode    => '0440',
    }

    package { 'neutron-plugin-openvswitch-agent':
        ensure  => 'present',
        require => Class['openstack::repo'],
    }

    file { '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini':
        content => template("openstack/${$openstack_version}/neutron/ovs_neutron_plugin.ini.erb"),
        owner   => 'neutron',
        group   => 'neutron',
        notify  => Service['neutron-server'],
        require => Package['neutron-server', 'neutron-plugin-openvswitch-agent'],
        mode    => '0440',
    }
}
