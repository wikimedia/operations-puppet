class contint::packages {

  # Make sure we use ant version 1.8 or we will have a conflict
  # with android
  include generic::packages::ant18

  include generic::packages::maven

  # Get perl dependencies so we can lint the wikibugs perl script
  include misc::irc::wikibugs::packages

  # Let us create packages from Jenkins jobs
  include misc::package-builder

  include svn::client

  # PHP related packages
  package { [
    'php-apc',
    'php-pear',
    'php5-cli',
    'php5-curl',
    'php5-gd',
    'php5-intl',
    'php5-mysql',
    'php5-pgsql',
    'php5-sqlite',
    'php5-tidy',
    'php5-xdebug',
    ]: ensure => present,
  }

  # luasandbox is a WMF package, we always want to use the very latest version
  # since the package is used by unit tests
  package { [
    'php-luasandbox',
  ]: ensure => latest,
  }

  # Database related
  package { [
    'mysql-server',
    'sqlite3',
    'postgresql',
    ]: ensure => present,
  }

  # Development packages
  package { [
    'imagemagick',
    'librsvg2-2',
    'librsvg2-bin',

    'asciidoc',
    'rake',

    'pep8',
    'pyflakes',
    'pylint',

    'luajit',
    'libevent-dev',  # PoolCounter daemon
    'liblua5.1-0-dev',
    'g++',
    'libthai-dev',

    'doxygen',
    ]: ensure => present,
  }

  # Includes packages needed for building
  # analytics and statistics related packages.

  # these are needed to build libanon and udp-filter
  package { ['pkg-config', 'libpcap-dev', 'libdb-dev']:
    ensure => 'installed',
  }

  # these packages are used by the tests for wikistats to parse the
  # generated reports to see if they are correct
  package { ['libhtml-treebuilder-xpath-perl','libweb-scraper-perl']:
    ensure => 'installed',
  }

  # need geoip to build udp-filter
  include geoip


  # Node.js evolves quickly so we want to update it
  # automatically.
  package { 'nodejs':
    ensure => latest,
  }

}
