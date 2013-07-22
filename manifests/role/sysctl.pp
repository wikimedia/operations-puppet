class role::sysctl::base {
    sysctl::conffile { 'wikimedia base':
        source => 'puppet:///files/sysctl/wikimedia-base.conf',
        priority => 50,
    }

    # Disable IPv6 privacy extensions, we rather not see our servers hide
    file { '/etc/sysctl.d/10-ipv6-privacy.conf':
        ensure => absent,
    }
}

class role::sysctl::advanced_routing_ipv6 {
    sysctl::conffile { 'advanced routing ipv6':
        source   => 'puppet:///files/sysctl/advanced-routing-ipv6.conf',
        priority => 50,
    }
}

class role::sysctl::advanced_routing {
    sysctl::conffile { 'advanced routing':
        source   => 'puppet:///files/sysctl/advanced-routing.conf',
        priority => 50,
    }
}

class role::sysctl::high_bandwidth_rsync {
    sysctl::conffile { 'high bandwidth rsync':
        source   => 'puppet:///files/sysctl/high-bandwidth-rsync.conf',
        priority => 60,
    }
}

class role::sysctl::high_http_performance {
    sysctl::conffile { 'high http performance':
        source   => 'puppet:///files/sysctl/high-http-performance.conf',
        priority => 60,
    }
}

class role::sysctl::ipv6_disable_ra {
    sysctl::conffile { 'ipv6 disable ra':
        source   => 'puppet:///files/sysctl/ipv6-disable-ra.conf',
        priority => 50,
    }
}

class role::sysctl::lvs {
    sysctl::conffile { 'lvs':
        source   => 'puppet:///files/sysctl/lvs.conf',
        priority => 50,
    }
}

class role::sysctl::big_rmem {
    sysctl::conffile { 'big rmem':
        source   => 'puppet:///files/sysctl/big-rmem.conf',
        priority => 99,
    }
}
