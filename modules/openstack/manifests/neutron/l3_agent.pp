class openstack::neutron::l3_agent(
    $version,
    $dmz_cidr_array,
    $network_public_ip,
    $report_interval,
    $enabled=true,
    ) {

    class { "openstack::neutron::l3_agent::${version}":
        dmz_cidr_array    => $dmz_cidr_array,
        network_public_ip => $network_public_ip,
        report_interval   => $report_interval,
    }

    class {'openstack::neutron::l3_agent_hacks':
        version => $version,
        require => Package['neutron-l3-agent'],
    }

    service {'neutron-l3-agent':
        ensure  => $enabled,
        require => Package['neutron-l3-agent'],
    }

    sysctl::parameters { 'openstack':
        values   => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter'    => 0,
            'net.ipv4.conf.all.rp_filter'        => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'                => 1,
            'net.ipv6.conf.all.forwarding'       => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'        => 0,

            # Increase connection tracking size
            # and bucket since all of CloudVPS VM instances ingress/egress
            # are flowing through cloudnet servers
            # default buckets is 65536. Let's use x4; 65536 * 4 = 262144
            # default max is buckets x4; 262144 * 4 = 1048576
            'net.netfilter.nf_conntrack_buckets' => 262144,
            'net.netfilter.nf_conntrack_max'     => 1048576,
        },
        priority => 50,
    }
}
