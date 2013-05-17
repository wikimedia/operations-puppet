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
    name       => $user,
    home       => $home,
    managehome => false,
    shell      => '/bin/bash',
    system     => true,
  }

  # Since home is not managed (we want to be manually clean up the home
  # directory), create the home dir "manually":
  file { $home:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0755',
  }
  # And the .ssh sub directory
  file { "${home}/.ssh":
    ensure  => directory,
    owner   => $user,
    group   => $user,
    mode    => '0700',
    require => File [$home],
  }

  # Finally publish the Jenkins master authorized key
  ssh_authorized_key { $ssh_key_name:
      ensure  => present,
      user    => $user,
      type    => 'ssh-rsa',
      key     => $ssh_authorized_key,
      target  => "${home}/.ssh/authorized_keys",
      options => $ssh_key_options,
      require => File["${home}/.ssh"],
  }

}
