# Class for website hosted on the continuous integration server
# https://integration.mediawiki.org/
# https://doc.wikimedia.org/
# https://doc.mediawiki.org/
class contint::website {

  # This is mostly to get the files properly setup
  file { '/srv/org':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }

  file { '/srv/org/mediawiki':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }
  file { '/srv/org/mediawiki/integration':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
  }

  # Apache configuration for integration.mediawiki.org
  file { '/etc/apache2/sites-available/integration.mediawiki.org':
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/contint/apache/integration.mediawiki.org',
  }
  apache_site { 'integration.mediawiki.org':
    name => 'integration.mediawiki.org'
  }

  file { '/srv/org/wikimedia':
    ensure => directory,
    mode   => '0755',
    owner  => 'www-data',
    group  => 'wikidev',
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
