#
# Holds all the packages needed for continuous integration.
#
# FIXME: split this!
#
class contint::packages {

    # Basic utilites needed for all Jenkins slaves
    include ::contint::packages::base

    # Ruby
    include ::contint::packages::ruby

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
        ]:
        ensure => present,
    }

    # Development packages
    package { [
        'librsvg2-2',

        'asciidoc',

        'pep8',
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

    # For Sphinx based documentation contain blockdiag diagrams
    require_package('libjpeg-dev')

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

    # JSDuck was built for Ubuntu ( T48236/ T82278 )
    # It is a pain to rebuild for Jessie so give up (T95008), we will use
    # bundler/rubygems instead
    if $::operatingsystem == 'Ubuntu' {
        package { 'ruby-jsduck':
            ensure => present,
        }
    }

    package { [
        'ocaml-nox',
        ]:
        ensure => present;
    }
}
