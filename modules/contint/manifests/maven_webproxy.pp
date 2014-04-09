# == Class contint::maven_webproxy
#
# Maintains maven settings for the jenkins-slave user
#
# == Parameters:
#
# [*homedir*] Base path where to write the maven configuration file
#
# [*user*]
# User name owning the .m2 directory
#
# [*group*]
# Group name owning the .m2 directory
#
class contint::maven_webproxy( $homedir, $user, $group ) {

  file { "${homedir}/.m2":
    ensure => 'directory',
    user   => $user,
    group  => $group,
  }

  file { "${homedir}/.m2/settings.xml":
    mode    => '0444',
    # Belong to root since we dont want anyone to change the settings
    user    => 'root',
    group   => 'root',
    content => template('contint/maven-webproxy.xml.erb'),
  }

}
