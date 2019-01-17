# == Class: jenkins::slave
#
class jenkins::slave(
    String $ssh_key,
    String $user = 'jenkins-slave',
    Stdlib::Unixpath $workdir = '/var/lib/jenkins-slave',
) {

    include ::jenkins::common

    group { $user:
        ensure => present,
        name   => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
        home       => '/var/lib/jenkins-slave',
    }

    file { $workdir:
        ensure  => directory,
        owner   => $user,
        group   => $user,
        mode    => '0775',
        require => User[$user],
    }

    # Finally publish the Jenkins master authorized key
    ssh::userkey { $user:
        ensure  => present,
        content => $ssh_key,
    }
}
