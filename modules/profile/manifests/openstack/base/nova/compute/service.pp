class profile::openstack::base::nova::compute::service(
    String $version = lookup('profile::openstack::base::version'),
    String $instance_dev = lookup('profile::openstack::base::nova::instance_dev'),
    String $network_flat_interface = lookup('profile::openstack::base::nova::network_flat_interface'),
    String $network_flat_tagged_base_interface = lookup('profile::openstack::base::nova::network_flat_tagged_base_interface'),
    String $network_flat_interface_vlan = lookup('profile::openstack::base::nova::network_flat_interface_vlan'),
    Boolean $legacy_vlan_naming = lookup('legacy_vlan_naming', {default_value => true}),
    Array[Stdlib::Fqdn] $all_cloudvirts = lookup('profile::openstack::base::nova::all_cloudvirts'),
    String $libvirt_cpu_model = lookup('profile::openstack::base::nova::libvirt_cpu_model'),
    Optional[Boolean] $enable_nova_rbd = lookup('profile::ceph::client::rbd::enable_nova_rbd', {'default_value' => false}),
    Optional[String] $ceph_rbd_pool = lookup('profile::ceph::client::rbd::pool', {'default_value' => undef}),
    Optional[String] $ceph_rbd_client_name = lookup('profile::ceph::client::rbd::client_name', {'default_value' => undef}),
    Optional[String] $libvirt_rbd_uuid = lookup('profile::ceph::client::rbd::libvirt_rbd_uuid', {'default_value' => undef}),
    ) {

    ensure_packages('conntrack')

    # If this node was previously a 'spare' node then it will have ferm installed
    #  which will interfere with various nova things
    package { 'ferm':
        ensure  => absent,
    }

    interface::tagged { $network_flat_interface:
        base_interface     => $network_flat_tagged_base_interface,
        vlan_id            => $network_flat_interface_vlan,
        method             => 'manual',
        up                 => 'ip link set $IFACE up',
        down               => 'ip link set $IFACE down',
        legacy_vlan_naming => $legacy_vlan_naming,
    }

    if $facts['fqdn'] =~ /^labvirt100[0-9].eqiad.wmnet/ {
        openstack::nova::compute::partition{ '/dev/sdb':
            before => File['/var/lib/nova/instances'],
        }
    }

    # The special value 'thinvirt' indicates that there's no local instance
    #  storage on this host. Ultimately all cloudvirts will be like this,
    #  at which point we won't need this hack.
    if $instance_dev != 'thinvirt' {
        file { '/var/lib/nova/instances':
            ensure  => 'directory',
            owner   => 'nova',
            group   => 'nova',
            recurse =>  true,
        }

        mount { '/var/lib/nova/instances':
            ensure  => mounted,
            device  => $instance_dev,
            fstype  => 'xfs',
            options => 'defaults',
            require => File['/var/lib/nova/instances'],
        }
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

    # Reuse the puppet cert as the labvirt cert
    #  Note that even though libvirtd.conf claims to let you
    #  configure these libvirt_ paths, it actually seems
    #  to hardcode things in places so best to stick with
    #  the paths listed below.
    $certpath = '/var/lib/nova'
    $libvirt_cert_pub  = "${certpath}/clientcert.pem"
    $libvirt_cert_priv = "${certpath}/clientkey.pem"
    $libvirt_cert_ca   = "${certpath}/cacert.pem"
    $puppet_cert_pub  = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca   = '/var/lib/puppet/ssl/certs/ca.pem'

    file { '/var/lib/nova/ssl/':
        ensure => directory,
    }

    file { $libvirt_cert_pub:
        ensure => present,
        source => "file://${puppet_cert_pub}",
        owner  => 'nova',
        group  => 'libvirt',
    }

    file { $libvirt_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        owner     => 'nova',
        group     => 'libvirt',
        mode      => '0640',
        show_diff => false,
    }

    file { $libvirt_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
        owner  => 'nova',
        group  => 'libvirt',
    }

    class {'openstack::nova::compute::service':
        version              => $version,
        libvirt_cpu_model    => $libvirt_cpu_model,
        certpath             => $certpath,
        all_cloudvirts       => $all_cloudvirts,
        ceph_rbd_pool        => $ceph_rbd_pool,
        ceph_rbd_client_name => $ceph_rbd_client_name,
        libvirt_rbd_uuid     => $libvirt_rbd_uuid,
        enable_nova_rbd      => $enable_nova_rbd,
    }
    contain 'openstack::nova::compute::service'

    class { 'prometheus::node_cloudvirt_ceph_network':
        ensure => present,
    }

    class { 'prometheus::node_cloudvirt_libvirt_stats': }

    if debian::codename::eq('bullseye') {
        grub::bootparam { 'disable_unified_cgroup_hierarchy':
            key   => 'systemd.unified_cgroup_hierarchy',
            value => '0',
        }
        grub::bootparam { 'disable_legacy_systemd_cgroup_controller':
            key   => 'systemd.legacy_systemd_cgroup_controller',
            value => '0',
        }
    }

    # this is not done at the user definition time due to only being needed for cloudvirts
    exec { 'Add nova user to libvirt-qemu group':
        command => '/usr/sbin/usermod -G libvirt-qemu nova',
        unless  => '/usr/bin/id nova | /usr/bin/grep -q -E \'\(libvirt-qemu\)\''
    }
}
