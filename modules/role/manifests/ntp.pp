# == Class role::ntp
#
# Ntp server role
class role::ntp {
    include standard::ntp
    system::role { 'ntp': description => 'NTP server' }


    # TODO: generate from $network::constants::all_networks
    $our_networks_acl = [
      '10.0.0.0 mask 255.0.0.0',
      '208.80.152.0 mask 255.255.252.0',
      '91.198.174.0 mask 255.255.255.0',
      '198.35.26.0 mask 255.255.254.0',
      '185.15.56.0 mask 255.255.252.0',
      '2620:0:860:: mask ffff:ffff:fffc::',
      '2a02:ec80:: mask ffff:ffff::',
     ]


    ntp::daemon { 'server':
        servers   => $::standard::ntp::peer_upstreams[$::fqdn],
        peers     => delete($::standard::ntp::wmf_all_peers, $::fqdn),
        time_acl  => $our_networks_acl,
        query_acl => $::standard::ntp::neon_acl,
    }

    ferm::service { 'ntp':
        proto => 'udp',
        port  => 'ntp',
    }

    monitoring::service { 'ntp peers':
        description   => 'NTP peers',
        check_command => 'check_ntp_peer!0.1!0.5';
    }

}
