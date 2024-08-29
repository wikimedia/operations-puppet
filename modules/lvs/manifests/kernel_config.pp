# Class: lvs::kernel_config
#
# Sets up kernel-level parameters for lvs
#
class lvs::kernel_config (
    Boolean $do_ipv6_ra_primary = false,
) {

    # ethtool is also a package needed but it is included from base
    file { '/etc/modprobe.d/lvs.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        content => template('lvs/lvs.conf.erb'),
        notify  => Exec['update-initramfs'],
    }

    # Prevent accidental iptables module loads
    kmod::blacklist { 'lvs-bl':
        modules => ['x_tables'],
    }

    sysctl::parameters { 'lvs':
        values => {
            # Turn off IP forwarding for security
            # LVS servers sit on all subnets
            'net.ipv4.ip_forward'             => 0,

            # early demux is a loss on router boxes
            'net.ipv4.ip_early_demux'         => 0,

            # Defenses (see http://www.linuxvirtualserver.org/docs/defense.html)
            # amemthresh is available mem threshold for triggering defenses,
            # specified in pages.  Default is 1024 (4MB).
            'net.ipv4.vs.amemthresh'          => 131072, # 512MB
            # Automatically start dropping likely synflood entries when memory is low:
            'net.ipv4.vs.drop_entry'          => 1,
            # Also schedule ICMPs, like e.g. fragmentation needed (needs Linux 4.4.0)
            'net.ipv4.vs.schedule_icmp'       => 1,

            # basic netdev tuning for 10GbE interfaces at full speed with RPS.
            # See deeper details in cacheproxy::performance
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
            # Bump the maximal number of ICMP packets sent per second from this
            # host from 1000 to 3000. Some of our load balancers receive more
            # than 1000 ICMP echo requests per second as documented in:
            # https://phabricator.wikimedia.org/T163312#3193182
            'net.ipv4.icmp_msgs_per_sec'      => 3000,
        },
    }

    if $do_ipv6_ra_primary {
        sysctl::parameters { 'lvs-ipv6-ra-primary':
            values => {
              # Control IPv6 RA processing.
              # We enable accept_ra on all interfaces, to support address autoconfig,
              # but disable accept_ra_defrtr by default so RAs on an interface don't
              # automatically cause a default route to be added via it (T358260)
              'net.ipv6.conf.all.accept_ra'            => 1,
              'net.ipv6.conf.default.accept_ra'        => 1,
              'net.ipv6.conf.all.accept_ra_defrtr'     => 0,
              'net.ipv6.conf.default.accept_ra_defrtr' => 0,
            }
        }
    }

    # The ip_vs kernel module is loaded upon pybal.service startup. However,
    # the sysctl parameters defined above are loaded during early boot by
    # systemd-sysctl.service. Add the module to modules-load.d, causing it to
    # be loaded statically before sysctl settings are applied as described in
    # sysctl.d(5).
    kmod::module { 'ip_vs':
        ensure => present,
    }

    # Bump min_free_kbytes a bit to ensure network buffers are available quickly
    vm::min_free_kbytes { 'lvs':
        pct => 3,
        min => 131072,
        max => 524288,
    }


}
