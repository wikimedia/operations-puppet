# Maintains maven settings for the jenkins-slave user
class contint::maven-webproxy {

  file { '/var/lib/jenkins-slave/.m2':
    ensure => directory,
  }

  file { '/var/lib/jenkins-slave/.m2/settings.xml':
    mode    => '0444',
    content => template('contint/maven-webproxy.xml.erb'),
  }

}
