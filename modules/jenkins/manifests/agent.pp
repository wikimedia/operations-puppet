# == Class: jenkins::agent
#
class jenkins::agent(
    String $ssh_key,
    String $user,
    Stdlib::Unixpath $workdir,
) {
    group { $user:
        ensure => present,
        name   => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
        home       => "/var/lib/${user}",
    }
    file { $workdir:
        ensure => directory,
        owner  => $user,
        group  => $user,
        mode   => '0775',
    }

    # Finally publish the Jenkins controller authorized key
    ssh::userkey { $user:
        ensure  => present,
        content => $ssh_key,
    }
}
