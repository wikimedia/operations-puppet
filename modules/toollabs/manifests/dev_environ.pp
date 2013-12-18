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
        'ant',
        'apt-file',
        'autoconf',
        'build-essential', # for dpkg
        'cvs',
        'cython',
        'dh-make-perl',
        'elinks',
        'emacs',
        'fakeroot', # for dpkg
        'gcj-jdk',                     # Bug 56995
        'ipython',                     # Bug 56995
        'libboost-python1.48-dev',
        'libdjvulibre-dev',            # Bug 56972
        'libdmtx-dev',                 # Bug #53867.
        'libfreetype6-dev',
        'libgdal1-dev',                # Bug 56995
        'libmariadbclient-dev',
        'libpng3-dev',
        'libproj-dev',                 # Bug 56995
        'libprotobuf-dev',             # Bug 56995
        'libsparsehash-dev',           # Bug 56995
        'libtiff4-dev', # bug 52717
        'libtool',
        'libvips-dev',
        'libxml2-dev',
        'libxslt-dev',
        'libxslt1-dev', # -- same
        'libzbar-dev',                 # Bug 56996
        'lintian',
        'links',
        'lynx',
        'mc', # Popular{{cn}} on Toolserver
        'mercurial',
        'openjdk-7-jdk',
        'pep8',                        # Bug 57863
        'pyflakes',                    # Bug 57863
        'p7zip-full', # requested by Betacommand to extract files using 7zip
        'python-dev',
        'python-coverage',             # Bug 57002
        'qt4-qmake',
        'sbt',
        'sqlite3',
        'subversion',
        'tig' ]:
        ensure => present
    }

    # TODO: deploy scripts
    # TODO: packager
}
