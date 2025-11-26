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
# @param $src_ips
#       If neither $src_ips nor $src_sets are provided, all source addresses will be allowed.
#       Otherwise only traffic coming from the addresses in the parameter and/or $src_sets
# @param $dst_ips: Likewise, but with destination addresses
# @param src_sets see srange docs
# @param dst_sets see srange docs
# @param notrack Optional boolean to disable connection tracking for matching traffic
# @param qos Optional string with value of 'high', 'low', 'normal' or 'mgmt' to indicate the
#       quality-of-service the traffic should get across the network, controlled by setting the
#       DSCP bits in the packet header.
define nftables::service (
    Wmflib::Protocol                     $proto,
    Wmflib::Ensure                       $ensure     = present,
    Integer[0,99]                        $prio       = 10,
    Optional[String]                     $desc       = undef,
    Optional[Nftables::Port]             $port       = undef,
    Optional[Firewall::Portrange]        $port_range = undef,
    Optional[Array[Stdlib::IP::Address]] $src_ips    = undef,
    Optional[Array[Stdlib::IP::Address]] $dst_ips    = undef,
    Optional[Array[String[1]]]           $src_sets   = undef,
    Optional[Array[String[1]]]           $dst_sets   = undef,
    Boolean                              $notrack    = false,
    Optional[Firewall::Qos]              $qos        = undef,
) {
    # TODO: there is a nftables construct 'concatenation' that can drastically
    # reduce the amount of filtering rules in the system.
    # this define doesn't support it, but we may in the future!
    # see https://wiki.nftables.org/wiki-nftables/index.php/Concatenations

    $port_stmt = nftables::port_stmt($proto, 'dport', $port, $port_range)

    $l3_v4_stmts = nftables::ip_stmt(
        4,
        $src_ips,
        $dst_ips,
        $src_sets,
        $dst_sets,
    )
    $l3_v6_stmts = nftables::ip_stmt(
        6,
        $src_ips,
        $dst_ips,
        $src_sets,
        $dst_sets,
    )

    $l3_stmts = ($l3_v4_stmts + $l3_v6_stmts)

    # Ensure all ips and sets were not defined before creating a port rule open
    # to all
    if (
        $l3_stmts == []
        and $src_ips == undef
        and $src_sets == undef
        and $dst_ips == undef
        and $dst_sets == undef
    ) {
        $rule_lines = nftables::ip_rules(undef, $port_stmt, [], 'accept')
        $notrack_lines = nftables::ip_rules(undef, $port_stmt, [], 'notrack')
    } else {
        $rule_lines = nftables::ip_rules($l3_stmts, $port_stmt, [], 'accept')
        $notrack_lines = nftables::ip_rules($l3_stmts, $port_stmt, [], 'notrack')
    }

    if $src_sets and $dst_sets {
        $file_require = Nftables::Set[$dst_sets + $src_sets]
    } elsif $dst_sets {
        $file_require = Nftables::Set[$dst_sets]
    } elsif $src_sets {
        $file_require = Nftables::Set[$src_sets]
    } else {
        $file_require = []
    }

    if $rule_lines != [] {
        $content = @("CONTENT")
        # Managed by puppet
        # ${desc}
        ${rule_lines.join("\n")}
        | CONTENT

        $filename = sprintf('/etc/nftables/input/%02d_%s.nft', $prio, $title)
        @file { $filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $content,
            notify  => Service['nftables'],
            require => $file_require,
            tag     => 'nft',
        }
    }

    if $notrack and $notrack_lines != [] {
        $notrack_content = @("CONTENT")
        # Managed by puppet
        # ${desc}
        ${notrack_lines.join("\n")}
        | CONTENT

        $notrack_filename = sprintf('/etc/nftables/notrack/%02d_%s.nft', $prio, $title)
        @file { $notrack_filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $notrack_content,
            notify  => Service['nftables'],
            require => $file_require,
            tag     => 'nft',
        }
    }

    if $qos != undef {
        # DSCP is set outbound, so we are marking the reply packets to those permitted
        # in the input chain by the rules compiled earlier.
        # In other words we need the same match criteria, but with 'saddr/daddr' reversed etc.
        $port_stmt_rev = nftables::port_stmt($proto, 'sport', $port, $port_range)

        $l3_v4_stmts_rev = nftables::ip_stmt(
            4,
            $dst_ips,
            $src_ips,
            $dst_sets,
            $src_sets,
        )
        $l3_v6_stmts_rev = nftables::ip_stmt(
            6,
            $dst_ips,
            $src_ips,
            $dst_sets,
            $src_sets,
        )

        $dscp_v4_lines = nftables::ip_rules(
            $l3_v4_stmts_rev,
            $port_stmt_rev,
            [nftables::dscp_stmt(4, $qos)],
            'return'
        )
        $dscp_v6_lines = nftables::ip_rules(
            $l3_v6_stmts_rev,
            $port_stmt_rev,
            [nftables::dscp_stmt(6, $qos)],
            'return'
        )
        $dscp_rules = ($dscp_v4_lines + $dscp_v6_lines).sort

        if $dscp_rules != [] {
            $postrouting_content = @("POST_CONTENT")
            # Managed by puppet
            # ${desc}
            ${dscp_rules.join("\n")}
            | POST_CONTENT

            $postrouting_filename = sprintf('/etc/nftables/postrouting/%02d_%s_service_%s.nft', $prio, $title, $qos)
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
}
