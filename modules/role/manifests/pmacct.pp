#
class role::pmacct {
    system::role { 'role::pmacct':
        description => 'pmacct netflow accounting',
    }

    include ::pmacct
    include ::base::firewall
    include ::standard

    $loopbacks = [
        # eqiad
        '208.80.154.196/30',
        '2620:0:861:ffff::/64',
        # codfw
        '208.80.153.192/29',
        '2620:0:860:ffff::/64',
        # esams
        '91.198.174.244/30',
        '2620:0:862:ffff::/64',
        # ulsfo
        '198.35.26.192/30',
        '2620:0:863:ffff::/64',
    ]

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => inline_template('(<%= @loopbacks.join(" ") %>)'),
    }

    ferm::service { 'netflow':
        proto  => 'udp',
        port   => '2100',
        desc   => 'NetFlow',
        srange => inline_template('(<%= @loopbacks.join(" ") %>)'),
    }
}
