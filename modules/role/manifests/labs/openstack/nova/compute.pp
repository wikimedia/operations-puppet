class role::labs::openstack::nova::compute($instance_dev='/dev/md1') {

    system::role { $name:
        description => 'openstack nova compute node',
    }

    require openstack
    include role::labs::openstack::nova::common
    $novaconfig = $role::labs::openstack::nova::common::novaconfig


    ganglia::plugin::python {'diskstat': }

    interface::tagged { $novaconfig['network_flat_interface']:
        base_interface => $novaconfig['network_flat_tagged_base_interface'],
        vlan_id        => $novaconfig['network_flat_interface_vlan'],
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class { '::openstack::nova::compute':
        novaconfig => $novaconfig,
    }

    mount { '/var/lib/nova/instances':
        ensure  => mounted,
        device  => $instance_dev,
        fstype  => 'xfs',
        options => 'defaults',
    }

    file { '/var/lib/nova/instances':
        ensure  => directory,
        owner   => 'nova',
        group   => 'nova',
        require => Mount['/var/lib/nova/instances'],
    }

    # Some older VMs have a hardcoded path to the emulator
    #  binary, /usr/bin/kvm.  Since the kvm/qemu reorg,
    #  new distros don't create a kvm binary.  We can safely
    #  alias kvm to qemu-system-x86_64 which keeps those old
    #  instances happy.
    file { '/usr/bin/kvm':
        ensure => link,
        target => '/usr/bin/qemu-system-x86_64',
    }

    # Increase the size of conntrack table size (default is 65536)
    #  T139598
    sysctl::parameters { 'nova_conntrack':
        values => {
            'net.netfilter.nf_conntrack_max'                   => 262144,
            'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
        },
    }

    file { '/etc/modprobe.d/nf_conntrack.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/firewall/nf_conntrack.conf',
    }

    diamond::collector { 'LibvirtKVM':
        source   => 'puppet:///modules/diamond/collector/libvirtkvm.py',
        settings => {
            # lint:ignore:quoted_booleans
            # This is jammed straight into a config file, needs quoting.
            'sort_by_uuid' => 'true',
            'disk_stats'   => 'true',
            # lint:endignore
        }
    }

    # Starting with 3.18 (34666d467cbf1e2e3c7bb15a63eccfb582cdd71f) the netfilter code
    # was split from the bridge kernel module into a separate module (br_netfilter)
    if (versioncmp($::kernelversion, '3.18') >= 0) {

        # This directory is shipped by systemd, but trusty's upstart job for kmod also
        # parses /etc/modules-load.d/ (but doesn't create the directory).
        file { '/etc/modules-load.d/':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        file { '/etc/modules-load.d/brnetfilter.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => File['/etc/modules-load.d/'],
            content => "br_netfilter\n",
        }
    }

    require_package('conntrack')
}
