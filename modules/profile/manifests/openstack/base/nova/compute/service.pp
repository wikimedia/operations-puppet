class profile::openstack::base::nova::compute::service(
    $version = hiera('profile::openstack::base::version'),
    $instance_dev = hiera('profile::openstack::base::nova::instance_dev'),
    $network_flat_interface = hiera('profile::openstack::base::nova::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::base::nova::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::base::nova::network_flat_interface_vlan'),
    Boolean $legacy_vlan_naming = lookup('legacy_vlan_naming', {default_value => true}),
    Array[Stdlib::Fqdn] $all_cloudvirts = lookup('profile::openstack::base::nova::all_cloudvirts')
    ) {

    require_package('conntrack')

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

    if $::fqdn =~ /^labvirt100[0-9].eqiad.wmnet/ {
        openstack::nova::compute::partition{ '/dev/sdb':
            before => File['/var/lib/nova/instances'],
        }
    }

    file { '/var/lib/nova/instances':
        ensure => 'directory',
        owner  => 'nova',
        group  => 'nova',
    }

    mount { '/var/lib/nova/instances':
        ensure  => mounted,
        device  => $instance_dev,
        fstype  => 'xfs',
        options => 'defaults',
        require => File['/var/lib/nova/instances'],
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

    class {'::openstack::nova::compute::service':
        version        => $version,
        certpath       => $certpath,
        all_cloudvirts => $all_cloudvirts,
        require        => Mount['/var/lib/nova/instances'],
    }
    contain '::openstack::nova::compute::service'
}
