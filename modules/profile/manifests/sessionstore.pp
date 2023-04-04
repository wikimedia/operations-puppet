# sets up a service for session storage (T206016)
class profile::sessionstore (
    Integer   $arp_ignore   = lookup('profile::sessionstore::arp_ignore', {'default_value' => 0}),
    Integer   $arp_announce = lookup('profile::sessionstore::arp_announce', {'default_value' => 0}),
) {

    # needed for T219560
    class {'passwords::cassandra': }

    # Experimental (to be removed after completion of T327954)
    sysctl::parameters { 'sessionstore-test':
        values   => {
            'net.ipv4.conf.all.arp_ignore'   => $arp_ignore,
            'net.ipv4.conf.all.arp_announce' => $arp_announce,
        },
        priority => 5,
    }
}
