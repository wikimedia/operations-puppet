# Class: toollabs::exec_environ
#
# This class sets up a node as an execution environment for tool labs.
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Actual runtime dependencies for tools live here.
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
class toollabs::exec_environ {
  include toollabs

  package { [
      'nodejs',
      'php5-curl',
      'mono-runtime',
      'php5-cli',
      'php5-mysql',
      'libhtml-parser-perl',
      'libwww-perl',
      'liburi-perl',
      'libdbd-sqlite3-perl',
      'mysql-client-core-5.5',
      'python-twisted',
      'python-virtualenv',
      'python-mysqldb',
      'python-requests',
      'python3',
      'mono-complete',
      'python-irclib',
      'adminbot',
      'gnuplot-nox',
      'libpod-simple-wiki-perl',
      'libxml-libxml-perl',
      'tcl',
      'tclcurl',
      'tcllib',
      'libthreads-shared-perl',
      'libthreads-perl',
      'p7zip' ]:
    ensure => present
  }

  # TODO: autofs overrides
  # TODO: PAM config
  # TODO: quotas
}

