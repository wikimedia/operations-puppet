# === class redis::multidc::ipsec
class redis::multidc::ipsec($shards) {
    #################################################################
    # Set up IPsec between hosts (for encrypting the redis replica) #
    #################################################################

    $my_ip = $facts['networking']['ip']
    $myshards = $shards.reduce([]) |$memo, $values| {
        $memo + $values[1].filter |$key, $value| { $value['host'] == $my_ip }.keys
    }
    $ipsec_host_list = $shards.reduce([]) |$memo, $values| {
        $memo + $values[1].filter |$key, $value| {
            $key in $myshards
        }.map |$key, $value| {
            ipresolve($value['host'], 'ptr')
        }
    }.sort.unique

    # No reason to define IPsec if the host doesn't need replication.
    if size($ipsec_host_list) > 0 {
        class { '::role::ipsec':
            hosts => $ipsec_host_list,
        }
    }
}
