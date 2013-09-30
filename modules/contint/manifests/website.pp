# Class for website hosted on the continuous integration server
# https://integration.mediawiki.org/
# https://doc.wikimedia.org/
class contint::website(
  $zuul_git_dir = '/var/lib/zuul/git'
){

  require contint::publish-console

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
  file { '/etc/apache2/sites-available/integration.wikimedia.org':
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => template('contint/apache/integration.wikimedia.org.erb'),
  }
  apache_site { 'integration.wikimedia.org':
    name => 'integration.wikimedia.org',
  }

  # Apache configuration for integration.mediawiki.org
  file { '/etc/apache2/sites-available/integration.mediawiki.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/integration.mediawiki.org',
  }
  apache_site { 'integration.mediawiki.org':
    name   => 'integration.mediawiki.org',
  }

  # Written to by jenkins for automatically generated
  # documentations
  file { '/srv/org/wikimedia/doc':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }
  file { '/etc/apache2/sites-available/doc.wikimedia.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/doc.wikimedia.org',
  }
  apache_site { 'doc.wikimedia.org':
    name => 'doc.wikimedia.org',
  }

  file { '/srv/localhost':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  file { '/srv/localhost/qunit':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins-slave',
    group  => 'jenkins-slave',
  }

  contint::localvhost { 'qunit':
    port       => 9412,
    docroot    => '/srv/localhost/qunit',
    log_prefix => 'qunit',
    require    => File['/srv/localhost/qunit'],
  }

}
