# == Class contint::maven_webproxy
#
# Maintains maven settings for the jenkins-slave user
#
# == Parameters:
#
# [*homedir*] Base path where to write the maven configuration file
#
class contint::maven_webproxy( $homedir ) {

  file { "${homedir}/.m2":
    ensure => 'directory',
  }

  file { "${homedir}/.m2/settings.xml":
    mode    => '0444',
    content => template('contint/maven-webproxy.xml.erb'),
  }

}
