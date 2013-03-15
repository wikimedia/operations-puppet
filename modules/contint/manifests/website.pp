# Class for website hosted on the continuous integration server
# https://integration.mediawiki.org/
# https://doc.wikimedia.org/
# https://doc.mediawiki.org/
class contint::website {

  # This is mostly to get the files properly setup
  file { '/srv/org':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/srv/org/wikimedia':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  file { '/srv/org/wikimedia/integration':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  # MediaWiki code coverage
  file { '/srv/org/wikimedia/integration/coverage':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  # Apache configuration for integration.wikimedia.org
  file { '/etc/apache2/sites-available/integration.wikimedia.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/integration.wikimedia.org',
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

  file { '/srv/localhost':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  file { '/srv/localhost/qunit':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  # Apache configuration for a virtual host on localhost
  file { '/etc/apache2/sites-available/qunit.localhost':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/qunit.localhost',
  }
  apache_site { 'qunit localhost':
    name => 'qunit.localhost'
  }

}
