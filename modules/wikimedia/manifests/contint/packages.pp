# vim: ts=2 sw=2 expandtab
class wikimedia::contint::packages {

  # Make sure we use ant version 1.8 or we will have a conflict
  # with android
  include ::generic::packages::ant18
  include ::generic::packages::git-core
  include ::generic::packages::maven
  include ::svn::client
  # Get perl dependencies so we can lint the wikibugs perl script
  include ::misc::irc::wikibugs::packages

  # split up packages into groups a bit for readability and flexibility
  # ("ensure present" vs. "ensure latest" ?)
  $CI_PHP_packages = [
    'php-apc',
    'php5-cli',
    'php5-curl',
    'php5-gd',
    'php5-intl',
    'php5-mysql',
    'php-pear',
    'php5-sqlite',
    'php5-tidy',
    'php5-pgsql',
  ]
  $CI_DB_packages  = [
    'mysql-server',
    'sqlite3',
    'postgresql',
  ]
  $CI_DEV_packages = [
    'imagemagick',
    'librsvg2-2',
    'librsvg2-bin',
    'pep8',
    'luajit',
    'liblua5.1-0-dev',
    'g++',
    'libthai-dev',
  ]
  $CI_DOC_packages = [ 'asciidoc' ]

  package { $CI_PHP_packages: ensure => present; }
  package { $CI_DB_packages: ensure => present; }
  package { $CI_DEV_packages: ensure => present; }
  package { $CI_DOC_packages: ensure => present; }

  package { 'rake': ensure => present; }

  # Node.js evolves quickly so we want to update it
  # automatically.
  package { 'nodejs': ensure => latest; }

  # Includes packages needed for building
  # analytics and statistics related packages.
  # E.g. udp-filter, etc.

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
  include ::geoip
}
