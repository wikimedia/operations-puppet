# === class redis::multidc::instances
class redis::multidc::instances($shards, $settings, $map) {
    #################################################################
    # Set up IPsec between hosts (for encrypting the redis replica) #
    #################################################################

    # This is actually more reliable than $::ipaddress for our uses
    $my_ip = ipresolve($::hostname, 4)

    $instances = redis_get_instances($my_ip, $shards)

    # TODO: maybe define a variable that can be tested separately from
    # mwprimary if we're switching just part of the datacenter
    $replica_map = redis_get_masters($my_ip, $shards, $::mwprimary)
    redis::instance{ $instances:
        ensure   => present,
        settings => $settings,
        map      => merge($map, $replica_map),
    }
}
