# lvs/balancer.pp

# Class: lvs::balancer
# Parameters:
#   - $service_ips: list of service IPs to bind to loopback
#   - $lvs_services: A configuration hash of LVS services
#   - $lvs_class_hosts: A configuration hash of PyBal class hosts
#   - $pybal_global_options: A configuration hash of PyBal global options
#   - $site: Site name used in PyBal configuration
class lvs::balancer(
    $service_ips=[],
    $lvs_services,
    $lvs_class_hosts,
    $pybal_global_options,
    $site
    ) {

    include pybal
    include cpufrequtils # defaults to "performance", Ubuntu default is "ondemand"

    # ethtool is also a package needed but it is included from base

    class { 'pybal::configuration':
        global_options => $pybal_global_options,
        lvs_services => $lvs_services,
        lvs_class_hosts => $lvs_class_hosts,
        site => $site
    }

    # XXX: Where to pull these node names from?
    class { 'confd':
        running => true,
        node    => 'http://localhost:2379',
    }

    file { '/etc/modprobe.d/lvs.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('lvs/lvs.conf.erb'),
        notify => Exec['update-initramfs-lvs-balancer']
    }

    exec { 'update-initramfs-lvs-balancer':
        command => '/usr/sbin/update-initramfs -u',
        refreshonly => true
    }

    # Bind balancer IPs to the loopback interface
    class { 'lvs::realserver': realserver_ips => $service_ips }

    sysctl::parameters { 'lvs':
        values => {
            # Turn OFF RP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Turn off IP forwarding for security
            # LVS servers sit on all subnets
            'net.ipv4.ip_forward'             => 0,

            # Disable the route cache
            # It is prone to DDoS attacks, and was even
            # removed in >= 3.6 kernels.
            'net.ipv4.rt_cache_rebuild_count' => -1,
        },
    }
}
