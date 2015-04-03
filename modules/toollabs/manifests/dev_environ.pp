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

    if os_version('ubuntu trusty') {
        package { [
            # Previously we installed libmariadbclient-dev, but that causes
            # dependency issues on Trusty.  libmariadbclient-dev formerly
            # provided libmysqlclient-dev, but not in trusty.
            # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=759309
            'libmysqlclient-dev',
            'libboost-python1.54-dev',
        ]:
            ensure  => latest,
        }
    } else {
        package { [
            'libmariadbclient-dev',
            'libboost-python1.48-dev',
        ]:
            ensure  => latest,
        }
    }

    package { [
        'ant',
        'apt-file',
        'autoconf',
        'build-essential', # for dpkg
        'byobu',                       # Bug T88989.
        'cmake',
        'cvs',
        'cython',
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'gcj-jdk',                     # Bug 56995
        'openjdk-7-jdk',
        'ipython',                     # Bug 56995
        'joe',                         # Bug 62236.
        'libdjvulibre-dev',            # Bug 56972
        'libdmtx-dev',                 # Bug #53867.
        'libfcgi-dev',                 # Bug #52902.
        'libfreetype6-dev',
        'libgdal1-dev',                # Bug 56995
        'libgeoip-dev',                # Bug 62649
        'libpng12-dev',
        'libproj-dev',                 # Bug 56995
        'libprotobuf-dev',             # Bug 56995
        'librsvg2-dev',                # Bug 58516
        'libsparsehash-dev',           # Bug 56995
        'libtiff4-dev', # bug 52717
        'libtool',
        'libvips-dev',
        'libxml2-dev',
        'libxslt1-dev',
        'libzbar-dev',                 # Bug 56996
        'links',
        'lintian',
        'lynx',
        'maven',
        'mc', # Popular{{cn}} on Toolserver
        'mercurial',
        'pastebinit',
        'pep8',                        # Bug 57863
        'pyflakes',                    # Bug 57863
        'python-coverage',             # Bug 57002
        'python-dev',
        'python3-dev',
        'qt4-qmake',
        'rlwrap',                      # Bug T87368
        'sbt',
        'sqlite3',
        'subversion',
        'tcl8.5-dev',
        'tig',
        'tmux',                        # Bug #65426.
        'valgrind' ]:                  # Bug T87117.
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
        ensure => link,
        target => '/usr/local/bin/webservice2',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        require => File['/usr/local/bin/webservice2'],
    }

    # TODO: deploy scripts
    # TODO: packager
}
