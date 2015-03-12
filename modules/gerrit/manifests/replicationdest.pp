# Setup the `gerritslave` account on any host that wants to receive
# replication. See role::gerrit::production::replicationdest
class gerrit::replicationdest( $ssh_key, $extra_groups = [], $slaveuser = 'gerritslave' ) {

    group { $slaveuser:
        ensure => present,
        name   => $slaveuser,
        system => true,
    }

    user { $slaveuser:
        name       => $slaveuser,
        groups     => $extra_groups,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    ssh::userkey { $slaveuser,
        ensure  => present,
        content => $ssh_key,
    }
}
