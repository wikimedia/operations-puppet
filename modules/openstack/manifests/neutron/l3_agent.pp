class openstack::neutron::l3_agent(
    $version,
    $dmz_cidr,
    $network_public_ip,
    $report_interval,
    $enabled=true,
    ) {

    if os_version('debian jessie') and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package { 'neutron-l3-agent':
        ensure          => 'present',
        install_options => $install_options,
    }

    class {'openstack::neutron::l3_agent_hacks':
        version => $version,
        require => Package['neutron-l3-agent'],
    }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0640',
            content => template("openstack/${version}/neutron/l3_agent.ini.erb"),
            require => Package['neutron-l3-agent'];
    }

    service {'neutron-l3-agent':
        ensure  => $enabled,
        require => Package['neutron-l3-agent'],
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
