# == Class: jenkins::slave
#
class jenkins::slave(
    $ssh_key,
    $user = 'jenkins-slave',
    $workdir = '/var/lib/jenkins-slave',
) {

    include jenkins::slave::requisites

    group { $user:
        ensure => present,
        name   => $user,
    }

    user { $user:
        ensure     => present,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
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
