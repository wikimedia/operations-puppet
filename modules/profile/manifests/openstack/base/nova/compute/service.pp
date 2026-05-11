# SPDX-License-Identifier: Apache-2.0
class profile::openstack::base::nova::compute::service(
    String $version = lookup('profile::openstack::base::version'),
    String $instance_dev = lookup('profile::openstack::base::nova::instance_dev'),
    String[1] $network_flat_interface = lookup('profile::openstack::base::nova::network_flat_interface'),
    Network::VLANTag $network_flat_interface_vlan = lookup('profile::openstack::base::nova::network_flat_interface_vlan'),
    Boolean $network_flat_set_mtu = lookup('profile::openstack::base::nova::compute::service::network_flat_set_mtu', {default_value => false}),
    Array[Stdlib::Fqdn] $all_cloudvirts = lookup('profile::openstack::base::nova::all_cloudvirts'),
    String $libvirt_cpu_model = lookup('profile::openstack::base::nova::libvirt_cpu_model'),
    Optional[Boolean] $enable_nova_rbd = lookup('profile::cloudceph::client::rbd::enable_nova_rbd', {'default_value' => false}),
    Optional[String] $ceph_rbd_pool = lookup('profile::cloudceph::client::rbd::pool', {'default_value' => undef}),
    Optional[String] $ceph_rbd_client_name = lookup('profile::cloudceph::client::rbd::client_name', {'default_value' => undef}),
    Optional[String] $libvirt_rbd_uuid = lookup('profile::cloudceph::client::rbd::libvirt_rbd_uuid', {'default_value' => undef}),
    Optional[String[1]] $compute_id = lookup('profile::openstack::base::nova::compute::id', {default_value => undef}),
    Optional[String] $cfssl_label = lookup('profile::openstack::base::nova::cfssl_label', {default_value => undef}),
    Optional[String] $private_hostname = lookup('profile::wmcs::cloud_private_subnet::host'),
) {
    ensure_packages('conntrack')

    # If this node was previously a 'spare' node then it will have ferm installed
    #  which will interfere with various nova things
    package { 'ferm':
        ensure  => absent,
    }

    interface::tagged { $network_flat_interface:
        base_interface => $facts['interface_primary'],
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
    }

    if $network_flat_set_mtu {
        interface::mtu { $network_flat_interface:
            mtu => 1500,
        }
    }

    if $instance_dev == 'srvlink' {
        # The special value 'srvlink' means that /srv was already created
        #  by partman (probably with lvm) and we just link to it.
        file { '/srv/instances':
            ensure  => 'directory',
            owner   => 'nova',
            group   => 'nova',
            recurse =>  true,
        }

        # The nova package will create an empty directory here,
        #  replace with a link
        file { '/var/lib/nova/instances':
            ensure  => 'link',
            owner   => 'nova',
            group   => 'nova',
            replace => true,
            force   => true,
            target  => '/srv/instances',
        }
    } else {
        if $instance_dev != 'thinvirt' {
            # The special value 'thinvirt' indicates that there's no local instance
            #  storage on this host. Ultimately all cloudvirts will be like this,
            #  at which point we won't need this hack.
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
    }

    # Increase the size of conntrack table size (default is 65536)
    #  T139598 T355222 T373816
    sysctl::parameters { 'nova_conntrack':
        values => {
            # 4 entries per bucket resembles the default ratio
            'net.netfilter.nf_conntrack_buckets'               => 8388608,  # 2^22
            'net.netfilter.nf_conntrack_max'                   => 33554432, # 4 * 2^22
            'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
        },
        module => 'nf_conntrack',
    }

    # We need to make sure the nf_conntrack kernel module is loaded at boot,
    # before systemd applies the custom settings defined in /etc/sysctl.d/*
    #
    # This is similar to what we do in modules/ferm/manifests/init.pp,
    # we also add it here because this profile does not include ferm.
    file { '/etc/modules-load.d/conntrack.conf':
        ensure  => present,
        mode    => '0444',
        content => "nf_conntrack\n",
    }

    kmod::options { 'nf_conntrack':
        options => 'hashsize=65536',
    }



    #  Note that even though libvirtd.conf claims to let you
    #  configure these libvirt_ paths, it actually seems
    #  to hardcode things in places so best to stick with
    #  the paths listed below.

    # The 'client*' names are hardcoded in the client code, but the server
    # config can specify custom paths. Since we're using a single cert for both
    # client and server they're both using 'client*' files instead of having
    # duplicates on disk.
    # Also note, the cacert file is only used for verification - the certs in
    # clientcert.pem must include the full chain.
    $certpath = '/var/lib/nova'
    $libvirt_cert_pub  = "${certpath}/clientcert.pem"
    $libvirt_cert_priv = "${certpath}/clientkey.pem"
    $libvirt_cert_ca   = "${certpath}/cacert.pem"


    if $cfssl_label {
        # Stage the cfssl certs here, then copy to the libvirt locations
        $sslpath = "${certpath}/ssl"
        file { $sslpath:
            ensure => directory,
        }

        $cert_paths = profile::pki::get_cert(
            $cfssl_label,
            $facts['networking']['fqdn'],
            {
                outdir        => $sslpath,
                provide_chain => true,
                owner         => 'nova',
                group         => 'libvirt',
                notify        => Service['nova-compute'],
                hosts         => [$facts['networking']['fqdn'],
                                  $private_hostname],
            }
        )

        file { $libvirt_cert_priv:
            ensure    => present,
            source    => "file://${cert_paths['key']}",
            owner     => 'nova',
            group     => 'libvirt',
            mode      => '0640',
            show_diff => false,
            notify    => Service['libvirtd'],
            require   => File[$cert_paths['key']],
        }

        file { $libvirt_cert_pub:
            ensure    => present,
            source    => "file://${cert_paths['cert']}",
            owner     => 'nova',
            group     => 'libvirt',
            mode      => '0644',
            show_diff => false,
            notify    => Service['libvirtd'],
            require   => File[$cert_paths['cert']],
        }

        # Here the 'chain' is the intermediate $cfssl_label CA cert
        # Therefore install it as our CA cert:
        # * Allow only certs from $cfssl_label CA
        # * Validate our client certificate is issued by $cfssl_label CA
        file { $libvirt_cert_ca:
            ensure    => present,
            source    => "file://${cert_paths['chain']}",
            owner     => 'nova',
            group     => 'libvirt',
            mode      => '0644',
            show_diff => false,
            notify    => Service['libvirtd'],
            require   => File[$cert_paths['chain']],
        }
    } else {
        # puppet CA based certs, legacy
        $puppet_cert_pub   = $facts['puppet_config']['hostcert']
        $puppet_cert_chain = $facts['puppet_config']['localcacert']
        $puppet_cert_priv  = $facts['puppet_config']['hostprivkey']

        concat { $libvirt_cert_pub:
            ensure => present,
            owner  => 'nova',
            group  => 'libvirt',
            notify => Service['libvirtd'],
        }

        concat::fragment { 'libvirtd_puppet_agent_cert':
            source => $puppet_cert_pub,
            order  => 1,
            target => $libvirt_cert_pub,
        }
        concat::fragment { 'libvirtd_puppet_cert_chain':
            source => $puppet_cert_chain,
            order  => 2,
            target => $libvirt_cert_pub,
        }

        file { $libvirt_cert_priv:
            ensure    => present,
            source    => "file://${puppet_cert_priv}",
            owner     => 'nova',
            group     => 'libvirt',
            mode      => '0640',
            show_diff => false,
            notify    => Service['libvirtd'],
        }

        file { $libvirt_cert_ca:
            ensure => present,
            source => "file://${puppet_cert_chain}",
            owner  => 'nova',
            group  => 'libvirt',
            notify => Service['libvirtd'],
        }
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
        compute_id           => $compute_id,
    }
    contain 'openstack::nova::compute::service'

    # this can be deleted
    class { 'prometheus::node_cloudvirt_ceph_network': }

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

    # script to run commands via consoles in an emergency
    file { '/usr/local/sbin/wmcs-run-console-command':
        ensure => file,
        source => 'puppet:///modules/profile/openstack/base/nova/compute/wmcs-run-console-command.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
