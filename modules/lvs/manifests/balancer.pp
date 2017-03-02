# lvs/balancer.pp

# Class: lvs::balancer
# Parameters:
#   - $service_ips: list of service IPs to bind to loopback
#   - $lvs_services: A configuration hash of LVS services
#   - $lvs_class_hosts: A configuration hash of PyBal class hosts
#   - $pybal_global_options: A configuration hash of PyBal global options
#   - $site: Site name used in PyBal configuration
class lvs::balancer(
    $lvs_services,
    $lvs_class_hosts,
    $pybal_global_options,
    $site,
    $service_ips=[],
    $conftool_prefix = '/conftool/v1',
    ) {

    include ::pybal
    include ::pybal::confd
    include ::cpufrequtils # defaults to "performance", Ubuntu default is "ondemand"
    include ::initramfs

    # ethtool is also a package needed but it is included from base

    class { '::pybal::configuration':
        global_options  => $pybal_global_options,
        lvs_services    => $lvs_services,
        lvs_class_hosts => $lvs_class_hosts,
        site            => $site,
        conftool_prefix => $conftool_prefix,
    }

    file { '/etc/modprobe.d/lvs.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('lvs/lvs.conf.erb'),
        notify  => Exec['update-initramfs'],
    }

    # Bind balancer IPs to the loopback interface
    class { '::lvs::realserver': realserver_ips => $service_ips }

    sysctl::parameters { 'lvs':
        values => {
            # Turn OFF RP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Turn off IP forwarding for security
            # LVS servers sit on all subnets
            'net.ipv4.ip_forward'             => 0,

            # Defenses (see http://www.linuxvirtualserver.org/docs/defense.html)
            # amemthresh is available mem threshold for triggering defenses,
            # specified in pages.  Default is 1024 (4MB).
            'net.ipv4.vs.amemthresh'          => 131072, # 512MB
            # Automatically start dropping likely synflood entries when memory is low:
            'net.ipv4.vs.drop_entry'          => 1,
            # Also schedule ICMPs, like e.g. fragmentation needed (needs Linux 4.4.0)
            'net.ipv4.vs.schedule_icmp'       => 1,

            # basic netdev tuning for 10GbE interfaces at full speed with RPS.
            # See deeper details in role::cache::perf
            'net.core.netdev_max_backlog'     => 300000,
            'net.core.netdev_budget'          => 1024,
            'net.core.netdev_tstamp_prequeue' => 0,

            # Add Echo Reply, Timestamp Reply, Info Reply, Address Mask Reply
            # to the default rate limit bitmask. For the definition of the
            # bitmask, see:
            # https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
            'net.ipv4.icmp_ratemask'          => 350233, # 1010101100000011001
            # Lower rate limit, as the default of 1000ms is way too large
            'net.ipv4.icmp_ratelimit'         => 200,
        },
    }
}
