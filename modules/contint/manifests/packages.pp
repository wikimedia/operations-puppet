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

    require_package('openjdk-7-jdk')

    package { 'maven2':
        ensure => present,
    }

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

    # Ruby
    if os_version('ubuntu <= trusty') {
        package { 'ruby1.9.3':
            ensure => present,
        }
    }
    if os_version('debian >= jessie') {
        package { 'ruby2.1':
            ensure => present,
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

    # frontend tests use curl to make http requests to mediawiki
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

    # JSDuck was built for Ubuntu ( T48236/ T82278 )
    # It is a pain to rebuild for Jessie so give up (T95008), we will use
    # bundler/rubygems instead
    if $::operatingsystem == 'Ubuntu' {
        package { 'ruby-jsduck':
            ensure => present,
        }
    }

    package { [
        'rubygems-integration',
        ]:
        ensure => present;
    }

    package { [
        'ocaml-nox',
        ]:
        ensure => present;
    }
}
