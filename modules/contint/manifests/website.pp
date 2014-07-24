# Class for website hosted on the continuous integration server
# https://integration.mediawiki.org/
# https://doc.wikimedia.org/
class contint::website(
  $zuul_git_dir = '/var/lib/zuul/git'
){

  require contint::publish-console

  # Need to send Vary: X-Forwarded-Proto since most sites are forced to HTTPS
  # and behind a varnish cache. See also bug 60822
  include ::apache::mod::headers

  # Static files in these docroots are in integration/docroot.git

  file { '/srv/org':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }

  file { '/srv/org/wikimedia':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }
  file { '/srv/org/wikimedia/integration':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }
  # MediaWiki code coverage
  file { '/srv/org/wikimedia/integration/coverage':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }

  # Jenkins console logs
  file { '/srv/org/wikimedia/integration/logs':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }

  # Apache configuration for integration.wikimedia.org
  file { '/etc/apache2/sites-enabled/integration.wikimedia.org':
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('contint/apache/integration.wikimedia.org.erb'),
  }

  # Apache configuration for integration.mediawiki.org
  file { '/etc/apache2/sites-enabled/integration.mediawiki.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/integration.mediawiki.org',
  }

  # Written to by jenkins for automatically generated
  # documentations
  file { '/srv/org/wikimedia/doc':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }
  file { '/etc/apache2/sites-enabled/doc.wikimedia.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/doc.wikimedia.org',
  }

}
