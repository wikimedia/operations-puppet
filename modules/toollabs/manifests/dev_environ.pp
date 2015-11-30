# Class: toollabs::dev_environ
#
# This class sets up a node as a dev environment for tool labs.
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Those are the dependencies for development tools and packages intended
# for interactive use.
#
# Parameters:
#
# Actions:
#   - Install tool dependencies
#
# Requires:
#
# Sample Usage:
#
class toollabs::dev_environ {
    include toollabs::composer

    if os_version('ubuntu trusty') {
        include toollabs::genpp::python_dev_trusty
        package { [
            # Previously we installed libmariadbclient-dev, but that causes
            # dependency issues on Trusty.  libmariadbclient-dev formerly
            # provided libmysqlclient-dev, but not in trusty.
            # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=759309
            'libmysqlclient-dev',
            'libboost-python1.54-dev',
            'redis-tools',
        ]:
            ensure  => latest,
        }
    } elsif os_version('ubuntu precise') {
        include toollabs::genpp::python_dev_precise
        package { [
            'libmariadbclient-dev',
            'libboost-python1.48-dev',
        ]:
            ensure  => latest,
        }
    } elsif os_version('debian jessie') {
        include toollabs::genpp::python_dev_jessie
        package { [
            'libmariadb-client-lgpl-dev',
            'libmariadb-client-lgpl-dev-compat',
            'libboost-python1.55-dev',
        ]:
            ensure  => latest,
        }
    }

    package { [
        'ant',
        'apt-file',
        'autoconf',
        'automake',                    # T119870
        'build-essential', # for dpkg
        'byobu',                       # T88989.
        'cmake',
        'cvs',
        'cython',
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'flex',                        # T114003.
        'gcj-jdk',                     # T58995
        'openjdk-7-jdk',
        'ipython',                     # T58995
        'joe',                         # T64236.
        'libdjvulibre-dev',            # T58972
        'libdmtx-dev',                 # T55867.
        'libfcgi-dev',                 # T54902.
        'libfreetype6-dev',
        'libgdal1-dev',                # T58995
        'libgeoip-dev',                # T64649
        'libpng12-dev',
        'libproj-dev',                 # T58995
        'libprotobuf-dev',             # T58995
        'librsvg2-dev',                # T60516
        'libsparsehash-dev',           # T58995
        'libtiff4-dev', # T54717
        'libtool',
        'libvips-dev',
        'libxml2-dev',
        'libxslt1-dev',
        'libzbar-dev',                 # T58996
        'links',
        'lintian',
        'lynx',
        'maven',
        'mc', # Popular{{cn}} on Toolserver
        'mercurial',
        'pastebinit',
        'pep8',                        # T59863
        'qt4-qmake',
        'rlwrap',                      # T87368
        'sbt',
        'sqlite3',
        'subversion',
        'tcl8.5-dev',
        'tig',
        'valgrind' ]:                  # T87117.
        ensure => latest,
    }

    # pastebinit configuration for http://tools.wmflabs.org/paste/.
    file { '/etc/pastebin.d':
        ensure  => 'directory',
        require => Package['pastebinit'],
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
    file { '/etc/pastebin.d/tools.conf':
        ensure  => 'file',
        require => File['/etc/pastebin.d'],
        source  => 'puppet:///modules/toollabs/pastebinit.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/bin/webservice2':
        ensure  => present,
        source  => 'puppet:///modules/toollabs/webservice2',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['python-yaml'], # Present on all hosts, defined for puppet diamond collector
    }

    file { '/usr/local/bin/webservice':
        ensure  => link,
        target  => '/usr/local/bin/webservice2',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/bin/webservice2'],
    }

    # TODO: deploy scripts
    # TODO: packager
}
