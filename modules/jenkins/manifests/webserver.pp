# Run Jenkins behind Apache and have pretty URLs / proxy port 80
# https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache
class jenkins::webserver {

  class { 'webserver::php5': ssl => true; }

  apache_module { 'proxy': name => 'proxy' }
  apache_module { 'proxy_http': name => 'proxy_http' }

  file { '/etc/apache2/conf.d/jenkins_proxy':
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/jenkins/apache_proxy',
  }
}
