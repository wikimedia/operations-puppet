# Class profile::nutcracker
#
# Configures a generic nutcracker instance
class profile::nutcracker(
    $pools = hiera('profile::nutcracker::pools')
) {
    include ::passwords::redis

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => $pools,
    }

    class { '::nutcracker::monitoring': }


    ferm::rule { 'skip_nutcracker_conntrack_out':
        desc  => 'Skip outgoing connection tracking for Nutcracker',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto tcp sport (6378:6382 11212) NOTRACK;',
    }

    ferm::rule { 'skip_nutcracker_conntrack_in':
        desc  => 'Skip incoming connection tracking for Nutcracker',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto tcp dport (6378:6382 11212) NOTRACK;',
    }

}
