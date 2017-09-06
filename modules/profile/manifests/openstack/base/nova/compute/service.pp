class profile::openstack::base::nova::compute::service(
    $version = hiera('profile::openstack::base::version'),
    $libvirt_type = hiera('profile::openstack::base::nova::libvirt_type'),
    $certname = hiera('profile::openstack::base::nova::certname'),
    $ca_target = hiera('profile::openstack::base::nova::ca_target'),
    $instance_dev = hiera('profile::openstack::base::nova::instance_dev'),
    $network_flat_interface = hiera('profile::openstack::base::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::base::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::base::nova::network_flat_interface_vlan'),
    ) {

    require_package('conntrack')
    ganglia::plugin::python {'diskstat': }

    if $::fqdn =~ /^labvirt100[0-9].eqiad.wmnet/ {
        openstack2::nova::compute::partition{ '/dev/sdb':}
    }

    interface::tagged { $network_flat_interface:
        base_interface => $network_flat_tagged_base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    mount { '/var/lib/nova/instances':
        ensure  => mounted,
        device  => $instance_dev,
        fstype  => 'xfs',
        options => 'defaults',
    }

    file { '/var/lib/nova/instances':
        ensure  => 'directory',
        owner   => 'nova',
        group   => 'nova',
        require => Mount['/var/lib/nova/instances'],
    }

    # Increase the size of conntrack table size (default is 65536)
    #  T139598
    sysctl::parameters { 'nova_conntrack':
        values => {
            'net.netfilter.nf_conntrack_max'                   => 262144,
            'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
        },
    }

    kmod::options { 'nf_conntrack':
        options => 'hashsize=32768',
    }

    class {'::openstack2::nova::compute::service':
        version      => $version,
        libvirt_type => $libvirt_type,
        certname     => $certname,
        ca_target    => $ca_target,
    }
}
