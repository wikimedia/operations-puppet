# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_authorized_key,
  $ssh_key_name,
  $ssh_key_options = [],
  $user = 'jenkins-slave',
  $workdir = '/var/lib/jenkins-slave',
) {

  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  systemuser { $user:
    ensure     => present,
    name       => $user,
    shell      => '/bin/bash',
  }

  file { $workdir:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    mode    => '0775',
    require => Systemuser[$user],
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
