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
    Wmflib::Ensure                       $ensure              = present,
    Integer[0,99]                        $prio                = 10,
    Optional[String]                     $desc                = undef,
    Optional[Nftables::Port]             $port                = undef,
    Optional[Firewall::Portrange]        $port_range          = undef,
    Optional[Array[Stdlib::IP::Address]] $src_ips             = undef,
    Optional[Array[Stdlib::IP::Address]] $dst_ips             = undef,
    Optional[Array[String[1]]]           $src_sets            = undef,
    Optional[Array[String[1]]]           $dst_sets            = undef,
    Optional[Boolean]                    $unrestricted_access = false,
    Boolean                              $notrack             = false,
    Optional[Firewall::Qos]              $qos                 = undef,
) {
    $rulesets = nftables::rulesets(
        'input',
        $proto,
        $port,
        $port_range,
        $src_ips,
        $dst_ips,
        $src_sets,
        $dst_sets,
        $qos
    )

    $file_require = nftables::require_sets($src_sets, $dst_sets)

    if $rulesets['base'] != [] {
        $content = @("CONTENT")
        # Managed by puppet
        # ${desc}
        ${rulesets['base'].join("\n")}
        | CONTENT

        $filename = sprintf('/etc/nftables/input/%02d_%s.nft', $prio, $title)
        @file { $filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $content,
            require => $file_require,
            tag     => 'nft',
        }
    }

    if $notrack and $rulesets['notrack'] != [] {
        $notrack_content = @("CONTENT")
        # Managed by puppet
        # ${desc}
        ${rulesets['notrack'].join("\n")}
        | CONTENT

        $notrack_filename = sprintf('/etc/nftables/notrack/%02d_%s.nft', $prio, $title)
        @file { $notrack_filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $notrack_content,
            require => $file_require,
            tag     => 'nft',
        }
    }

    if $qos != undef and $rulesets['dscp'] != [] {
        $postrouting_content = @("POST_CONTENT")
        # Managed by puppet
        # ${desc}
        ${rulesets['dscp'].join("\n")}
        | POST_CONTENT

        $postrouting_filename = sprintf('/etc/nftables/postrouting/%02d_%s_service_%s.nft', $prio, $title, $qos)
        @file { $postrouting_filename:
            ensure  => $ensure,
            mode    => '0444',
            content => $postrouting_content,
            require => $file_require,
            tag     => 'nft',
        }
    }
}
