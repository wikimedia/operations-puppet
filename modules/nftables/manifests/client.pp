# SPDX-License-Identifier: Apache-2.0
# @summary Create nft rules for a client (permit outbound)
# @param ensure Ensure of the resource
# @param proto Either 'udp' or 'tcp'
# @param prio The rules are included with a path prefix, by default all rules use 10,
#             but if ordering matters for a given service it can also be lower or higher
# @param desc An optional description which gets added as a comment to the .nft file
# @param port Either a port or an array of allowed ports. If neither port or port_range are set,
#       all ports are allowed
# @param port_range A tuple of ports represending an allowed range. If neither port or port_range
#             are set, all ports are allowed
# @param $src_ips
#       If neither $src_ips nor $src_sets are provided, all source addresses will be allowed.
#       Otherwise only traffic coming from the addresses in the parameter and/or $src_sets
# @param $dst_ips: Likewise, but with destination addresses
# @param src_sets see srange docs
# @param dst_sets see srange docs
# @param notrack Optional boolean to disable connection tracking for matching traffic
# @param qos Optional string with value of 'high', 'low', 'normal' or 'control' to indicate the
#       quality-of-service the traffic should get across the network, controlled by setting the
#       DSCP bits in the packet header.
# @param skip_output_chain
#       Controls whether or not to create a rule in the output chain matching the defined 
#       traffic, which is usually not needed.  Defaults to true to match the existing 
#       ferm::client behaviour.
define nftables::client (
    Wmflib::Protocol              $proto,
    Wmflib::Ensure                $ensure            = present,
    Integer[0,99]                 $prio              = 10,
    Optional[String]              $desc              = undef,
    Optional[Nftables::Port]      $port              = undef,
    Optional[Firewall::Portrange] $port_range        = undef,
    Array[Stdlib::IP::Address]    $src_ips           = [],
    Array[Stdlib::IP::Address]    $dst_ips           = [],
    Array[String[1]]              $src_sets          = [],
    Array[String[1]]              $dst_sets          = [],
    Boolean                       $notrack           = false,
    Boolean                       $skip_output_chain = false,
    Optional[Firewall::Qos]       $qos               = undef,
) {
    # TODO: there is a nftables construct 'concatenation' that can drastically
    # reduce the amount of filtering rules in the system.
    # this define doesn't support it, but we may in the future!
    # see https://wiki.nftables.org/wiki-nftables/index.php/Concatenations

    $_port = $port.then |$x| { [$x].flatten }

    # figure out transport protocol statements
    if !$_port.empty() and $port_range {
        fail("${title}: You can only pass an array of ports or a range, but not both")
    }

    if !$_port.empty() {
        $port_stmt = "${proto} dport { ${_port.sort.join(', ')} }"
    } elsif $port_range {
        if $port_range[0] >= $port_range[1] {
            fail("${title}: Incorrect port range ${port_range[0]} >= ${port_range[1]}")
        }
        $port_stmt = "${proto} dport ${port_range.join('-')}"
    } elsif $port.empty() and !$port_range {
        fail("${title}: You need at least one of port or port_range")
    }

    # figure out IPv4 source statements
    $src_ipv4_addrs = $src_ips.filter |$host| { $host =~ Stdlib::IP::Address::V4 }.sort.unique
    $src_raw_v4_stmts = [ $src_ipv4_addrs.empty.bool2str('', "ip saddr { ${src_ipv4_addrs.join(', ')} }") ]
    $src_set_v4_stmts = $src_sets.map |$set| { "ip saddr @${set}_ipv4" }
    $src_v4 = $src_raw_v4_stmts + $src_set_v4_stmts

    # figure out IPv4 dest statements
    $dst_ipv4_addrs = $dst_ips.filter |$host| { $host =~ Stdlib::IP::Address::V4 }.sort.unique
    $dst_raw_v4_stmts = [ $dst_ipv4_addrs.empty.bool2str('', "ip daddr { ${dst_ipv4_addrs.join(', ')} }") ]
    $dst_set_v4_stmts = $dst_sets.map |$set| { "ip daddr @${set}_ipv4" }
    $dst_v4 = $dst_raw_v4_stmts + $dst_set_v4_stmts

    # figure out combination of IPv4 src and dest statements
    $maybe_l3_v4_stmts = $src_v4.map |$src| {
        $dst_v4.map |$dst| {
            "${src} ${dst}".strip
        }
    }.flatten.sort.filter |$x| { $x !~ /^\s*$/ }

    # T351094: Ensure that we have valid v4 addresses after filtering.
    # This prevents us from having an empty rule if e.g. dst_ips contains no ipv4 address
    if ($src_ipv4_addrs.empty and !$src_ips.empty) or ($dst_ipv4_addrs.empty and !$dst_ips.empty) {
        $l3_v4_stmts = []
    } else {
        # Remove smaller statements that are contained in stricter rules, to avoid firewall holes.
        # I understand if this gives you headache, so let me explain:
        # if we are producing 2 rules:
        #  "ip saddr 1.1.1.1 accept"
        #  "ip saddr 1.1.1.1 ip daddr 2.2.2.2 accept"
        # the second rule wont ever match because packets are accepted by the first. The first rule
        # is what we are killing here, because we have an stricter one.
        # Filter the 'maybe statements', and remove each statement that is contained in other statements.
        $l3_v4_stmts = $maybe_l3_v4_stmts.filter |$i| {
            ! $maybe_l3_v4_stmts.filter |$j| { $i != $j }.reduce(false) |$memo, $x| {
                $memo or ($i in $x)
            }
        }
    }

    # figure out IPv6 source statements
    $src_ipv6_addrs = $src_ips.filter |$host| { $host =~ Stdlib::IP::Address::V6 }.sort.unique
    $src_raw_v6_stmts = [ $src_ipv6_addrs.empty.bool2str('', "ip6 saddr { ${src_ipv6_addrs.join(', ')} }") ]
    $src_set_v6_stmts = $src_sets.map |$set| { "ip6 saddr @${set}_ipv6" }
    $src_v6 = $src_raw_v6_stmts + $src_set_v6_stmts

    # figure out IPv6 dest statements
    $dst_ipv6_addrs = $dst_ips.filter |$host| { $host =~ Stdlib::IP::Address::V6 }.sort.unique
    $dst_raw_v6_stmts = [ $dst_ipv6_addrs.empty.bool2str('', "ip6 daddr { ${dst_ipv6_addrs.join(', ')} }") ]
    $dst_set_v6_stmts = $dst_sets.map |$set| { "ip6 daddr @${set}_ipv6" }
    $dst_v6 = $dst_raw_v6_stmts + $dst_set_v6_stmts

    # figure out combination of IPv6 src and dest statements
    $maybe_l3_v6_stmts = $src_v6.map |$src| {
        $dst_v6.map |$dst| {
            "${src} ${dst}".strip
        }
    }.flatten.sort.filter |$x| { $x !~ /^\s*$/ }

    # T351094: Ensure that we have valid v4 addresses after filtering.
    # This prevents us from having an empty rule if e.g. dst_ips contains no ipv4 address
    if ($src_ipv6_addrs.empty and !$src_ips.empty) or ($dst_ipv6_addrs.empty and !$dst_ips.empty) {
        $l3_v6_stmts = []
    } else {
        # See comment above about contained statements and headache
        $l3_v6_stmts = $maybe_l3_v6_stmts.filter |$i| {
            ! $maybe_l3_v6_stmts.filter |$j| { $i != $j }.reduce(false) |$memo, $x| {
                $memo or ($i in $x)
            }
        }
    }

    $l3_stmts = ($l3_v4_stmts + $l3_v6_stmts).sort
    $rules = $l3_stmts.empty() ? {
        true => ["${port_stmt} accept"],
        default => $l3_stmts.map |$l3_stmt| { "${l3_stmt} ${port_stmt} accept".strip },
    }

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

    if $notrack {
        $notrack_rule = regsubst($content, 'accept$', 'notrack')

        $notrack_filename = sprintf('/etc/nftables/notrack/%02d_%s.nft', $prio, $title)
        @file { $notrack_filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $notrack_rule,
            notify  => Service['nftables'],
            require => $file_require,
            tag     => 'nft',
        }
    }

    if !$skip_output_chain {
        $filename = sprintf('/etc/nftables/output/%02d_%s.nft', $prio, $title)
        @file { $filename:
            ensure  => $ensure,
            mode    => '0444',
            content => $content,
            notify  => Service['nftables'],
            require => $file_require,
            tag     => 'nft',
        }
    }

    if $qos != undef {
        $dscp = firewall::qos2dscp($qos)

        $dscp_v4_rules = $l3_v4_stmts.empty() ? {
            true => ["${port_stmt} ip dscp set ${dscp} return"],
            default => $l3_v4_stmts.map |$l3_v4_stmt| { "${l3_v4_stmt} ${port_stmt} ip dscp set ${dscp} return".strip },
        }

        $dscp_v6_rules = $l3_v6_stmts.empty() ? {
            true => ["${port_stmt} ip6 dscp set ${dscp} return"],
            default => $l3_v6_stmts.map |$l3_v6_stmt| { "${l3_v6_stmt} ${port_stmt} ip6 dscp set ${dscp} return".strip },
        }

        $dscp_rules = ($dscp_v4_rules + $dscp_v6_rules).sort

        $postrouting_content = @("POST_CONTENT")
        # Managed by puppet
        # ${desc}
        ${dscp_rules.join("\n")}
        | POST_CONTENT

        $postrouting_filename = sprintf('/etc/nftables/postrouting/%02d_%s_client_%s.nft', $prio, $title, $qos)
        @file { $postrouting_filename:
            ensure  => $ensure,
            mode    => '0444',
            content => $postrouting_content,
            notify  => Service['nftables'],
            require => $file_require,
            tag     => 'nft',
        }
    }
}
