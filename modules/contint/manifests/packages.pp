class contint::packages {

  # Make sure we use ant version 1.8 or we will have a conflict
  # with android
  include generic::packages::ant18

  include generic::packages::maven

  # Get perl dependencies so we can lint the wikibugs perl script
  include misc::irc::wikibugs::packages

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
    ]: ensure => present,
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
    'liblua5.1-0-dev',
    'g++',
    'libthai-dev',
    ]: ensure => present,
  }

  # Node.js evolves quickly so we want to update it
  # automatically.
  package { 'nodejs':
    ensure => latest,
  }

}
