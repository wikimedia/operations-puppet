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
      'libtool',
      'libxml2-dev',
      'libxslt-dev',
      'autoconf',
      'sqlite3',
      'python-dev',
      'libmariadbclient-dev',
      'libpng3-dev',
      'libfreetype6-dev',
      'lintian',
      'apt-file',
      'dh-make-perl',
      'emacs',
      'elinks',
      'mercurial',
      'mosh',
      'tig',
      'fakeroot', # for dpkg
      'build-essential', # for dpkg
      'mc', # midnight commander is favorite on toolserver, let's not make labs worse than toolserver
      'libxslt1-dev', # -- same
      'p7zip-full', # requested by Betacommand to extract files using 7zip
      'subversion',
      'cython' ]:
    ensure => present
  }

  # TODO: deploy scripts
  # TODO: packager
}
