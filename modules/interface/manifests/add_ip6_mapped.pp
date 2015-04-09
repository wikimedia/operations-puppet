define interface::add_ip6_mapped($interface=undef, $ipv4_address=undef) {
    if ! $interface {
        $all_interfaces = split($::interfaces, ',')
        $intf = $all_interfaces[0]
    }
    else {
        $intf = $interface
    }

    if ! member(split($::interfaces, ','), $intf) {
        warning("Not adding IPv6 address to ${intf} because this interface does not exist!")
    }
    else {
        if ! $ipv4_address {
            $ip4_address = "::${::ipaddress}"
        }
        else {
            $ip4_address = "::${ipv4_address}"
        }

        # $v6_mapped_lower64 looks like '::10:0:2:1' for a v4 of '10.0.2.1'
        $v6_mapped_lower64 = regsubst($ip4_address, '\.', ':', 'G')

        # XXX Temporary: testing on cp1008 first in a couple of different scenarios...
        if $::hostname == 'cp1008' {

            ############
            # Set address without relying on kernel autoconf (but still using RA prefix from network)...
            ############

            # This provides the "rdisc6" command
            package { 'ndisc6': ensure => present }

            # Takes args like "eth0 ::1:2:3:4", uses rdisc6 to get network prefix
            #  and combines the two into a whole output address
            file { '/usr/local/sbin/get_v6_mapped':
                owner   => 'root',
                group   => 'root',
                mode    => '0555',
                source  => 'puppet:///modules/interface/get_v6_mapped.rb',
                require => Package['ndisc6'],
            }

            $get_addr_cmd = "/usr/local/sbin/get_v6_mapped ${intf} ${v6_mapped_lower64}"
            $ipaddr_cmd = "ip addr add $(${get_addr_cmd}) dev ${intf}"

            # Use augeas to add an 'up' command to the interface
            augeas { "${intf}_ip6_mapped":
                context => "/files/etc/network/interfaces/*[. = '${interface}' and ./family = 'inet']",
                changes => "set up[last()+1] '${ipaddr_cmd}'",
                onlyif  => "match up[. = '${ipaddr_cmd}'] size == 0",
                require => File['/usr/local/sbin/get_v6_mapped'],
            }

            # Add the IP address manually as well when above first added
            exec { "${intf}_ip6_mapped":
                command => $ipaddr_cmd,
                refreshonly => true,
                subscribe => Augeas["${intf}_ip6_mapped"],
            }

            ############
            # Deal with disabling autoconf...
            ############

            # This sets a pre-up command to disable accepting prefixes, which
            # should disable the creation of macaddr-based autoconf addresses
            # (on fresh boots when this is already set in the file...)
            $v6_no_pinfo_cmd = "echo 0 >/proc/sys/net/ipv6/conf/${intf}/accept_ra_pinfo"
            $v6_no_pinfo_preup_cmd = "set iface[. = '${intf}']/pre-up '${v6_no_pinfo_cmd}'"
            augeas { "${intf}_v6_no_pinfo":
                context => '/files/etc/network/interfaces/',
                changes => $v6_no_pinfo_preup_cmd,
            }

            # This sets it as a sysctl as well, which has the side effect of
            # getting the parameter applied immediately for hosts that are
            # already booted (so they'll stop accepting new prefixes, but
            # still have a lingering autoconf address expiring slowly)
            sysctl::parameters { "${intf}_v6_no_pinfo":
                values => { "net.ipv6.conf.${inft}.accept_ra_pinfo" => 0 }
            }

            # This flushes the lingering address left behind above, IFF augeas
            # took action (we didn't have these settings before this run), and
            # after the sysctl above has run to suppress further updates.
            exec { "${intf}_v6_flush_dynamic":
                command => "/sbin/ip -6 addr flush dev ${intf} dynamic",
                refreshonly => true,
                subscribe => Augeas["${intf}_v6_no_pinfo"],
                require => Exec['update_sysctl'],
            }

        } # XXX end cp1008 testing block
        else {
            $ipv6_address = inline_template("<%= require 'ipaddr'; (IPAddr.new(scope.lookupvar(\"::ipaddress6_${intf}\")).mask(64) | IPAddr.new(v6_mapped_lower64)).to_s() %>")
            interface::ip { $title:
                interface => $intf,
                address   => $ipv6_address,
                prefixlen => '64'
            }
        }
    }
}
