# Class for website hosted on the continuous integration server
# https://integration.wikimedia.org
class contint::website {

  # This is mostly to get the files properly setup
  file { '/srv/org':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }

  file { '/srv/org/wikimedia':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }
  file { '/srv/org/wikimedia/integration':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }
  # MediaWiki code coverage
  file { '/srv/org/mediawiki/integration/coverage':
    ensure => directory,
    mode   => '0775',
    owner  => 'jenkins',
    group  => 'wikidev',
  }

  # Apache configuration for integration.wikimedia.org
  file { '/etc/apache2/sites-available/integration.wikimedia.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/integration.wikimedia.org',
  }
  apache_site { 'integration.mediawiki.org':
    # Make sure the old configuration does not conflict
    ensure => absent,
    name => 'integration.mediawiki.org',
  }
  apache_site { 'integration.wikimedia.org':
    name => 'integration.wikimedia.org'
  }

  file { '/srv/localhost':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }
  file { '/srv/localhost/qunit':
    ensure => directory,
    mode   => '0755',
    owner  => 'jenkins',
    group  => 'wikidev',
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
