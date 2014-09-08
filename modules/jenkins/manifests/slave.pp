# == Class: jenkins::slave
#
class jenkins::slave(
    $ssh_authorized_key,
    $ssh_key_name,
    $ssh_key_options = [],
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
    ssh_authorized_key { $ssh_key_name:
        ensure  => present,
        user    => $user,
        type    => 'ssh-rsa',
        key     => $ssh_authorized_key,
        options => $ssh_key_options,
    }

}
