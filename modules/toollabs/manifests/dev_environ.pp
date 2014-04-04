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

    package { [
        'apt-file',
        'autoconf',
        'build-essential', # for dpkg
        'cmake',
        'cvs',
        'cython',
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'gcj-jdk',                     # Bug 56995
        'ipython',                     # Bug 56995
        'joe',                         # Bug 62236.
        'libboost-python1.48-dev',
        'libdjvulibre-dev',            # Bug 56972
        'libdmtx-dev',                 # Bug #53867.
        'libfcgi-dev',                 # Bug #52902.
        'libfreetype6-dev',
        'libgdal1-dev',                # Bug 56995
        'libgeoip-dev',                # Bug 62649
        'libmariadbclient-dev',
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
        'lintian',
        'links',
        'lynx',
        'maven',
        'mc', # Popular{{cn}} on Toolserver
        'mercurial',
        'npm',
        'openjdk-7-jdk',
        'pastebinit',
        'pep8',                        # Bug 57863
        'pyflakes',                    # Bug 57863
        'p7zip-full', # requested by Betacommand to extract files using 7zip
        'python-dev',
        'python-coverage',             # Bug 57002
        'qt4-qmake',
        'sbt',
        'sqlite3',
        'subversion',
        'tcl8.5-dev',
        'tig',
        'tmux' ]:                      # Bug #65426.
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

    # TODO: deploy scripts
    # TODO: packager
}
