# === class redis::multidc::instances
class redis::multidc::instances($shards, $settings, $map) {
    #################################################################
    # Set up IPsec between hosts (for encrypting the redis replica) #
    #################################################################

    $instances = redis_get_instances($::ipaddress, $shards)

    # TODO: maybe define a variable that can be tested separately from
    # mwprimary if we're switching just part of the datacenter
    $replica_map = redis_get_masters($::ipaddress, $shards, $::mw_primary)
    redis::instance{ $instances:
        ensure   => present,
        settings => $settings,
        map      => merge($map, $replica_map),
    }
}
