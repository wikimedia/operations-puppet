# vim: ts=2 sw=2 expandtab
class wikimedia::contint::jdk {
# JDK for android continuous integration
# extra stuff for license agreement acceptance
# Based off of http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html

  package { 'debconf-utils':
    ensure => installed
  }

  exec { 'agree-to-jdk-license':
    command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
    unless  => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
    path    => ['/bin', '/usr/bin'],
    require => Package['debconf-utils'],
  }

  exec { "agree-to-jre-license":
    command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
    unless  => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
    path    => ['/bin', '/usr/bin'],
    require => Package['debconf-utils'],
  }

  package { 'sun-java6-jdk':
    ensure  => latest,
    require => [ Exec['agree-to-jdk-license'] ],
  }

  package { 'sun-java6-jre':
    ensure  => latest,
    require => [ Exec['agree-to-jre-license'] ],
  }

}
