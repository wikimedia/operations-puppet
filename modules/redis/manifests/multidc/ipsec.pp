# === class redis::multidc::ipsec
class redis::multidc::ipsec($shards) {
    #################################################################
    # Set up IPsec between hosts (for encrypting the redis replica) #
    #################################################################

    # This is actually more reliable than $::ipaddress for our uses
    $my_ip = ipresolve($::fqdn, 4)
    $ipsec_host_list = redis_shard_hosts($my_ip, $shards)

    class { 'role::ipsec':
        hosts => $ipsec_host_list
    }
}
