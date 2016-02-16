# === class redis::multidc::instances
class redis::multidc::instances($shards, $settings, $map) {
    #################################################################
    # Set up IPsec between hosts (for encrypting the redis replica) #
    #################################################################

    $ip = $::main_ipaddress
    $instances = redis_get_instances($ip, $shards)

    # TODO: maybe define a variable that can be tested separately from
    # mw_primary if we're switching just part of the datacenter
    $replica_map = redis_add_replica($map, $ip, $shards, $::mw_primary)

    redis::instance{ $instances:
        ensure   => present,
        settings => $settings,
        map      => $replica_map,
    }
}
