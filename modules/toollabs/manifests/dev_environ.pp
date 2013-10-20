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
      'cython',
      'dh-make-perl',
      'elinks',
      'emacs',
      'fakeroot', # for dpkg
      'libboost-python1.48-dev',
      'libdmtx-dev',                 # Bug #53867.
      'libfreetype6-dev',
      'libmariadbclient-dev',
      'libpng3-dev',
      'libtiff4-dev', # bug 52717
      'libtool',
      'libvips-dev',
      'libxml2-dev',
      'libxslt-dev',
      'libxslt1-dev', # -- same
      'lintian',
      'mc', # Popular{{cn}} on Toolserver
      'mercurial',
      'openjdk-7-jdk',
      'p7zip-full', # requested by Betacommand to extract files using 7zip
      'python-dev',
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
