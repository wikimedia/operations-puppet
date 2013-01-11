# vim: ts=2 sw=2 expandtab
class wikimedia::contint::webserver {
  # Common apache configuration
  apache_site { 'integration':
    name => 'integration.mediawiki.org'
  }

  apache_module { 'proxy': name => 'proxy' }
  apache_module { 'proxy_http': name => 'proxy_http' }
  apache_module { 'rewrite': name => "rewrite" }

  # run jenkins behind Apache and have pretty URLs / proxy port 80
  # https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache
  class {'webserver::php5': ssl => true; }

  file {
    '/etc/apache2/conf.d/jenkins_proxy':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/wikimedia/contint/apache/jenkins_proxy';
    '/etc/apache2/conf.d/zuul_proxy':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/wikimedia/contint/apache/zuul_proxy';
  }

  file {
    # Placing the file in sites-available
    '/etc/apache2/sites-available/integration.mediawiki.org':
      path   => '/etc/apache2/sites-available/integration.mediawiki.org',
      mode   => '0444',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/wikimedia/contint/apache/integration.mediawiki.org';
  }

  file {
    # Let wikidev users maintain the homepage
    '/srv/org':
      ensure => directory,
      mode   => '0755',
      owner  => www-data,
      group  => wikidev;
    '/srv/org/mediawiki':
      ensure => directory,
      mode   => '0755',
      owner  => www-data,
      group  => wikidev;
  }
}
