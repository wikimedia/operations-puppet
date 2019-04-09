# This class sets up a node as a dev environment for Toolforge.
# This is a "sub" role included by the actual Toolforge roles and would
# normally not be included directly in node definitions.
#
# Those are the dependencies for development tools and packages intended
# for interactive use.

class toollabs::dev_environ {

    include ::toollabs::composer

    if os_version('debian jessie') {
        include ::toollabs::genpp::python_dev_jessie
        include ::phabricator::arcanist # T139738
        package { [
            'bundler',  # T120287
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
        'ipython',                     # T58995
        'joe',                         # T64236.
        'libdjvulibre-dev',            # T58972
        'libdmtx-dev',                 # T55867.
        'libfcgi-dev',                 # T54902.
        'libfreetype6-dev',
        'libgdal1-dev',                # T58995
        'libgeoip-dev',                # T64649
        'libldap2-dev',                # T114388
        'libpng12-dev',
        'libproj-dev',                 # T58995
        'libprotobuf-dev',             # T58995
        'librsvg2-dev',                # T60516
        'libsasl2-dev',                # T114388
        'libsparsehash-dev',           # T58995
        'libssl-dev',                  # T114388
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
        'mytop',                       # T58999
        'openjdk-7-jdk',
        'pastebinit',
        'pep8',                        # T59863
        'qt4-qmake',
        'rake',                        # T120287
        'rlwrap',                      # T87368
        'ruby-dev',                    # T120287
        'sbt',
        'subversion',
        'tcl8.5-dev',
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
        source  => 'puppet:///modules/toollabs/pastebinit.conf',
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
