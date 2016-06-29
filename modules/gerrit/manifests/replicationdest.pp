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
        require    => Group[$slaveuser],
    }

    ssh::userkey { $slaveuser:
        ensure  => present,
        content => $ssh_key,
        require => User[$slaveuser],
    }

    # Add ytterbium to ssh exceptions for git replication
    ferm::service { 'ytterbium_ssh_git':
        proto  => 'tcp',
        port   => '22',
        srange => '@resolve((ytterbium.wikimedia.org gerrit.wikimedia.org))',
    }
}
