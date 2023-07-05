# SPDX-License-Identifier: Apache-2.0
# @summary Create nft rules for a service
# @param ensure Ensure of the resource
# @param proto Either 'udp' or 'tcp'
# @param prio The rules are included with a path prefix, by default all rules use 10,
#             but if ordering matters for a given service it can also be lower or higher
# @param desc An optional description which gets added as a comment to the .nft file
# @param port Either a port or an array of allowed ports. If neither port or port_range are set,
#       all ports are allowed
# @param port_range A tuple of ports represending an allowed range. If neither port or port_range
#             are set, all ports are allowed
# @param srange
#       If neither $srange nor $src_sets are provided, all source addresses will be allowed.
#       Otherwise only traffic coming from $srange (specified as hosts/networks) and/or $src_sets
#       (specified via predefined sets of servers will be allowed.
# @param drange / $dst_sets: Likewise, but with destination addresses
# @param src_sets see srange docs
# @param dst_sets see srange docs
# @param notrack disable state tracking for this rule
define nftables::service (
    Ferm::Protocol             $proto,
    Wmflib::Ensure             $ensure     = present,
    Integer[1,99]              $prio       = 10,
    Optional[String]           $desc       = undef,
    Array[Stdlib::Port]        $port       = undef,
    Optional[Ferm::Portrange]  $port_range = undef,
    Array[Stdlib::IP::Address] $src_ips    = [],
    Array[Stdlib::IP::Address] $dst_ips    = [],
    Array[String[1]]           $src_sets   = [],
    Array[String[1]]           $dst_sets   = [],
    Boolean                    $notrack    = false,
) {
    # figure out transport protocol statements
    if !$port.empty() and $port_range {
        fail('You can only pass an array of ports or a range, but not both')
    }

    if !$port.empty {
        $port_spec = "{${port}.join(',')}"
        $port_stmt = "${proto} dport ${port_spec}"
    } elsif $port_range {
        $port_spec = "${port_range[0]}-${port_range[1]}"
        $port_stmt = "${proto} dport ${port_spec}"
    } elsif !$port_range and !$port {
        $port_stmt = ''
    }
    # TODO: notrack doesn't have any effect yet

    # figure out raw src statements
    $src_ipv4_addrs = $src_ips.filter |$host| { $host =~ Stdlib::IP::Address::V4 }
    $src_ipv6_addrs = $src_ips.filter |$host| { $host =~ Stdlib::IP::Address::V6 }

    $src_raw_v4_stmt = $src_ipv4_addrs.map |$src| {
        $src.empty.bool2str('', "ip saddr {${src}.join(',')}")
    }

    $src_raw_v6_stmt = $src_ipv6_addrs.map |$src| {
        $src.empty.bool2str('', "ip6 saddr {${src}.join(',')}")
    }

    # figure out dst statements
    $dst_ipv4_addrs = $dst_ips.filter |$host| { $host =~ Stdlib::IP::Address::V4 }
    $dst_ipv6_addrs = $dst_ips.filter |$host| { $host =~ Stdlib::IP::Address::V6 }

    $dst_raw_v4_stmt = $dst_ipv4_addrs.map |$dst| {
        $dst.empty.bool2str('', "ip daddr {${dst}.join(',')}")
    }

    $dst_raw_v6_stmt = $dst_ipv6_addrs.map |$dst| {
        $dst.empty.bool2str('', "ip6 daddr {${dst}.join(',')}")
    }
    $src_set_v4_stmt = $src_sets.map |$set| { "ip saddr @${set}_ipv4" }
    $src_set_v6_stmt = $src_sets.map |$set| { "ip6 saddr @${set}_ipv6" }
    $dst_set_v4_stmt = $dst_sets.map |$set| { "ip daddr @${set}_ipv4" }
    $dst_set_v6_stmt = $dst_sets.map |$set| { "ip6 daddr @${set}_ipv6" }

    # figure out l3 proto match matrix
    $l3_v4_stmts = ($src_raw_v4_stmt + $src_set_v4_stmt).map |$src_stmt| {
        ($dst_raw_v4_stmt + $dst_set_v4_stmt).each |$dst_stmt| {
            "${src_stmt} ${dst_stmt}"
        }
    }

    $l3_v6_stmts = ($src_raw_v6_stmt + $src_set_v6_stmt).map |$src_stmt| {
        ($dst_raw_v6_stmt + $dst_set_v6_stmt).each |$dst_stmt| {
            "${src_stmt} ${dst_stmt}"
        }
    }

    # finally, generate rules from the statements
    $rules = ($l3_v4_stmts + $l3_v6_stmts).map |$l3_stmt| { "${l3_stmt} ${port_stmt} accept" }

    $content = @("CONTENT")
    # Managed by puppet
    # ${desc}
    ${rules.join("\n")}
    | CONTENT

    if $src_sets and $dst_sets {
        $file_require = Nftables::Set[$dst_sets + $src_sets]
    } elsif $dst_sets {
        $file_require = Nftables::Set[$dst_sets]
    } elsif $src_sets {
        $file_require = Nftables::Set[src_sets]
    } else {
        $file_require = undef
    }
    @file { "/etc/nftables/input/${name}.nft":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $content,
        notify  => Service['nftables'],
        require => $file_require,
    }
}
