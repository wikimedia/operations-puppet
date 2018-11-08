# This class sets up a node as a dev environment for tool labs.
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Those are the dependencies for development tools and packages intended
# for interactive use.

class profile::toolforge::dev_environ {

    file { '/srv/composer':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => '/srv/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
        require            => File['/srv/composer'],
    }

    # Create a symbolic link for the composer executable.
    file { '/usr/local/bin/composer':
        ensure  => 'link',
        target  => '/srv/composer/vendor/bin/composer',
        owner   => 'root',
        group   => 'root',
        require => Git::Clone['composer'],
    }

    if os_version('ubuntu trusty') {
        include profile::toolforge::genpp::python_dev_trusty
        class {'::phabricator::arcanist': } # T139738
        package { [
            'bundler',  # T120287
            # Previously we installed libmariadbclient-dev, but that causes
            # dependency issues on Trusty.  libmariadbclient-dev formerly
            # provided libmysqlclient-dev, but not in trusty.
            # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=759309
            'libmysqlclient-dev',
            'libboost-python1.54-dev',
            'redis-tools',
            'openjdk-7-jdk',
            'mytop',                       # T58999
            'libpng12-dev',
            'libtiff4-dev', # T54717
            'tcl8.5-dev',
            'libgdal1-dev',                # T58995
            'sbt',
        ]:
            ensure  => latest,
        }
    } elsif os_version('debian jessie') {
        include profile::toolforge::genpp::python_dev_jessie
        class {'::phabricator::arcanist': } # T139738
        package { [
            'bundler',  # T120287
            'libmariadb-client-lgpl-dev',
            'libmariadb-client-lgpl-dev-compat',
            'libboost-python1.55-dev',
            'openjdk-7-jdk',
            'libpng12-dev',
            'mytop',                       # T58999
            'libtiff4-dev', # T54717
            'tcl8.5-dev',
            'libgdal1-dev',                # T58995
            'sbt',
        ]:
            ensure  => latest,
        }
    } elsif os_version('debian stretch') {
        include profile::toolforge::genpp::python_dev_stretch
        class {'::phabricator::arcanist': } # T139738
        package { [
            'bundler',  # T120287
            'libmariadb-dev',
            'libmariadb-dev-compat',
            'libboost-python1.67-dev',
            'openjdk-8-jdk',
            'libpng-dev',
            'libtiff5-dev',  # T54717
            'tcl-dev',
            'libkml-dev',
            'libgdal-dev',                # T58995
            'mariadb-client-10.1',
            # sbt is not in the official repos -- scala is not well supported
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
        'ipython',                     # T58995
        'joe',                         # T64236.
        'libdjvulibre-dev',            # T58972
        'libdmtx-dev',                 # T55867.
        'libfcgi-dev',                 # T54902.
        'libfreetype6-dev',
        'libgeoip-dev',                # T64649
        'libldap2-dev',                # T114388
        'libproj-dev',                 # T58995
        'libprotobuf-dev',             # T58995
        'librsvg2-dev',                # T60516
        'libsasl2-dev',                # T114388
        'libsparsehash-dev',           # T58995
        'libssl-dev',                  # T114388
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
        'rake',                        # T120287
        'rlwrap',                      # T87368
        'ruby-dev',                    # T120287
        'subversion',
        'tig',
        'valgrind',                    # T87117.
    ]:
        ensure => latest,
    }

    # pastebinit configuration for https://tools.wmflabs.org/paste/.
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
        source  => 'puppet:///modules/profile/toolforge/pastebinit.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { [
        '/usr/local/bin/webservice2',
        '/usr/local/bin/webservice',
    ]:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
