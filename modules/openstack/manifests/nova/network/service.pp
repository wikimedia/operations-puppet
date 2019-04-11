# Nova-network is the network service currently used in Labs; some day soon
#  we hope to replace it with Neutron.
# http://docs.openstack.org/openstack-ops/content/nova-network-deprecation.html
class openstack::nova::network::service(
    $active,
    $version,
    $dns_recursor,
    $dns_recursor_secondary,
    $dnsmasq_classles_static_route,
    $tftp_host='install1002.wikimedia.org',
    ) {

    $recursor_ip = ipresolve($dns_recursor,4)
    $recursor_secondary_ip = ipresolve($dns_recursor_secondary,4)

    package {  [ 'nova-network', 'dnsmasq' ]:
        ensure  => 'present',
    }

    file { '/etc/dnsmasq-nova.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("openstack/${version}/nova/network/dnsmasq-nova.conf.erb"),
        notify  => Service['nova-network'],
    }

    # Firewall is managed by nova-network outside of ferm
    # Do Not Include Base::Firewall

    file { '/etc/modprobe.d/nf_conntrack.conf':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/firewall/nf_conntrack.conf',
        notify => Service['nova-network'],
    }

    # dnsmasq is run manually by nova-network, we don't want the service running
    service { 'dnsmasq':
        ensure  => stopped,
        enable  => false,
        require => Package['dnsmasq'];
    }

    service { 'nova-network':
        ensure    => $active,
        subscribe => File['/etc/nova/nova.conf'],
        require   => Package['nova-network'];
    }

    sysctl::parameters { 'openstack':
        values   => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'             => 1,
            'net.ipv6.conf.all.forwarding'    => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'     => 0,

            # Increase connection tracking size
            # and bucket since all of labs is
            # tracked on the network host
            'net.netfilter.nf_conntrack_max'  => 262144,
        },
        priority => 50,
    }
}
