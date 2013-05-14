# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_authorized_key,
  $ssh_key_name,
  $ssh_key_options = [],
  $user = 'jenkins-slave',
  $home = '/home/jenkins-slave',
) {

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  group { $user:
    ensure    => present,
    name      => $user,
    system    => true,
    allowdupe => false,
  }

  user { $user:
    ensure     => present,
    require    => Group['jenkins'],
    name       => $user,
    gid        => 'jenkins',
    home       => $home,
    managehome => false,
    shell      => '/bin/bash',
    system     => true,
  }

  ssh_authorized_key { $ssh_key_name:
      ensure  => present,
      user    => $user,
      type    => 'ssh-rsa',
      key     => $ssh_authorized_key,
      target  => "${home}/.ssh/authorized_keys",
      options => $ssh_key_options,
  }

}
