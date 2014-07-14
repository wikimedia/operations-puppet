define beta::natdestrewrite( $public_ip, $private_ip ) {

    include base::firewall

    # iptables -t nat -I OUTPUT --dest $public_ip -j DNAT --to-dest $private_ip
    ferm::rule { "nat_rewrite_for_${name}":
        ensure => 'absent',
        table  => 'nat',
        chain  => 'OUTPUT',
        domain => 'ip',
        rule   => "daddr ${public_ip} { DNAT to ${private_ip}; }",
    }
}

