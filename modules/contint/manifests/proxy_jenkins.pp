# A http proxy in front of Jenkins
class contint::proxy_jenkins {

  include proxy_common

  # run jenkins behind Apache and have pretty URLs / proxy port 80
  # https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

  file {
    '/etc/apache2/conf.d/jenkins_proxy':
      ensure => absent,
  }

  file {
    '/etc/apache2/jenkins_proxy':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/contint/apache/proxy_jenkins',
  }

}
