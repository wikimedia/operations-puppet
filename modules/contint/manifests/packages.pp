#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    include androidsdk::dependencies

    # Get several OpenJDK packages including the jdk to build mobile
    # applications.
    # (openjdk is the default distribution for the java define.
    # The java define is found in modules/java/manifests/init.pp )
    if ! defined ( Package['openjdk-6-jdk'] ) {
        package { 'openjdk-6-jdk': ensure => present }
    }
    if ! defined ( Package['openjdk-7-jdk'] ) {
        package { 'openjdk-7-jdk': ensure => present }
    }

    package { 'maven2':
        ensure => present,
    }

    # Lint authdns templates & config
    include authdns::lint

    include subversion::client

    # PHP related packages
    package { [
        'php-pear',
        'php5-cli',
        'php5-curl',
        'php5-dev',  # phpize
        'php5-gd',
        'php5-intl',
        'php5-mysql',
        'php5-parsekit',
        'php5-pgsql',
        'php5-sqlite',
        'php5-tidy',
        'php5-xdebug',
        ]:
        ensure => present,
    }

    # luasandbox is a WMF package, we always want to use the very latest version
    # since the package is used by unit tests
    package { [
        'php-luasandbox',
        ]:
        ensure => latest,
    }

    # Database related
    package { [
        'mysql-server',
        'sqlite3',
        'postgresql',
        ]:
        ensure => present,
    }

    # Development packages
    package { [
        'librsvg2-2',
        'librsvg2-bin',

        'asciidoc',
        'rake',
        'ruby1.9.3',  # To let us syntax check scripts using 1.9

        'pep8',
        'pyflakes',
        'pylint',

        'python-simplejson',  # For mw/ext/Translate among others

        'luajit',
        'libevent-dev',  # PoolCounter daemon
        'liblua5.1-0-dev',
        'g++',
        'libthai-dev',

        'doxygen',
        'python-sphinx',  # python documentation
        'ruby-jsduck',
        ]:
        ensure => present,
    }

    if ! defined ( Package['python-requests'] ) {
        package { 'python-requests':
            ensure => present,
        }
    }


    # Includes packages needed for building
    # analytics and statistics related packages.

    # these are needed to build libanon and udp-filter
    package { ['pkg-config', 'libpcap-dev', 'libdb-dev']:
        ensure => 'installed',
    }

    # Used to build analytics udp-filters
    package { ['libcidr0-dev', 'libanon0-dev']:
        ensure => 'latest',
    }

    # Used for mobile device classification in Kraken:
    package { [
        'libdclass0',
        'libdclass0-dev',
        'libdclass-jni',
        'libdclass-java',
        'libdclass-data',
        ]:
        ensure => 'installed',
    }

    # these packages are used by the tests for wikistats to parse the
    # generated reports to see if they are correct

    package { [
        'libhtml-treebuilder-xpath-perl',
        'libjson-xs-perl',
        'libnet-patricia-perl',
        'libtemplate-perl',
        'libweb-scraper-perl',
        ]:
        ensure => 'installed',
    }

    # need geoip to build udp-filter
    include geoip

    # Node.js evolves quickly so we want to update it
    # automatically.
    package { 'nodejs':
        ensure => latest,
    }

    # qunit tests depends on curl
    package { [
        'curl',
        ]:
        ensure => present,
    }

    # Colordiff gives us nice coloring in Jenkins console whenever
    # it is used instead of the stock diff.
    package { 'colordiff':
        ensure => present,
    }

    # Uninstalled packages
    package { [
        'php-apc',
        ]: ensure => absent,
    }

    # Packages to support use of rspec on puppet modules:
    package { [
    # Packages imported from Debian Sid:
    # Most of these would be pulled in via dependencies
    # from ruby-rspec but I'm enumerating them here as a note
    # that the standard ubuntu versions are insufficient.
        'rubygems-integration',
        'ruby-metaclass',
        'ruby-rspec-mocks',
        'ruby-rspec-expectations',
        'ruby-mocha',
        'ruby-rspec',
        'ruby-rspec-core',
    # Packages built using gem2deb:
        'ruby-rspec-puppet',
        'ruby-puppetlabs-spec-helper',
        ]:
        ensure => present;
    }

    package { [
        'djvulibre-bin',
        ]:
        ensure => present;
    }

    package { [
        'ocaml-nox',
        ]:
        ensure => present;
    }
}
