#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    include ::mediawiki::packages
    include ::mediawiki::packages::multimedia  # T76661

    if os_version('ubuntu < trusty') {
        # Disable APC entirely it gets confused when files changes often
        file { '/etc/php5/conf.d/apc.ini':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/contint/disable-apc.ini',
            require => Package['php-apc'],
        }
    }
    # Get several OpenJDK packages including the jdk to build mobile
    # applications.
    # (openjdk is the default distribution for the java define.
    # The java define is found in modules/java/manifests/init.pp )
    if ! os_version( 'debian >= jessie' ) {
        # No more available in Jessie
        require_package('openjdk-6-jdk')
    }
    require_package('openjdk-7-jdk')

    package { 'maven2':
        ensure => present,
    }

    # Lint authdns templates & config
    include authdns::lint

    include subversion::client

    # PHP related packages
    package { [
        'php5-dev',  # phpize
        'php5-gd',
        'php5-pgsql',
        'php5-sqlite',
        'php5-tidy',
        'php5-xdebug',
        ]:
        ensure => present,
    }
    package { [
        'php5-parsekit',
        ]:
        ensure => absent,
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

    # For Doxygen based documentations
    require_package('graphviz')

    require_package('python-requests')

    # Node.js evolves quickly so we want to update automatically.
    require_package('nodejs')


    # Includes packages needed for building
    # analytics and statistics related packages.

    # these are needed to build libanon and udp-filter
    package { ['pkg-config', 'libpcap-dev', 'libdb-dev']:
        ensure => 'installed',
    }

    if os_version('ubuntu < trusty') {
        # Packages that are not available on Trusty.
        # The related Jenkins jobs need to be rewritten anyway.

        # Used to build analytics udp-filters
        package { ['libcidr0-dev', 'libanon0-dev']:
            ensure => 'latest',
        }
    }

    if os_version('ubuntu >= trusty') {

        # Provide 'node' alias for 'nodejs' because Debian/Ubuntu
        # already has a package called 'node'
        package { 'nodejs-legacy':
            ensure => latest,
        }
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
        'ocaml-nox',
        ]:
        ensure => present;
    }
}
