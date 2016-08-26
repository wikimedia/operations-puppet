class sonarqube {

  package { 'openjdk-8-jdk-headless':
    ensure => present,
  }

  package { 'sonar':
    ensure  => present,
    require => Package['openjdk-8-jdk-headless'],
  }

}