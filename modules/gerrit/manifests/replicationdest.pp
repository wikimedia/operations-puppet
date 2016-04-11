# Setup the `gerritslave` account on any host that wants to receive
# replication. See role::gerrit::production::replicationdest
class gerrit::replicationdest( $ssh_key, $slaveuser = 'gerritslave' ) {

    group { $slaveuser:
        ensure => present,
        name   => $slaveuser,
        system => true,
    }

    user { $slaveuser:
        name       => $slaveuser,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    ssh::userkey { $slaveuser:
        ensure  => present,
        content => $ssh_key,
    }

    # Add ytterbium to ssh exceptions for git replication
    ferm::rule { 'ytterbium_ssh_git':
        rule => 'proto tcp dport ssh { saddr (208.80.154.80 208.80.154.81 2620:0:861:3:92b1:1cff:fe2a:e60 2620:0:861:3:208:80:154:80 2620:0:861:3:208:80:154:81) ACCEPT; }'
    }
}
