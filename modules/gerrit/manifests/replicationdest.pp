# Setup the `gerritslave` account on any host that wants to receive
# replication. See role::gerrit::production::replicationdest
class gerrit::replicationdest( $sshkey, $extra_groups = [], $slaveuser = 'gerritslave' ) {

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

    ssh_authorized_key { $slaveuser:
        ensure  => present,
        key     => $sshkey,
        type    => 'ssh-rsa',
        user    => $slaveuser,
        require => User[$slaveuser],
    }
}
