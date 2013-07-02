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
  include generic::locales::international
  include identd

  package { [
      'mariadb-client',              # For /usr/bin/mysql.
      'mdbtools',                    # Bug #48805.
      'python-genshi',               # Bug #48863.
      'python-genshi-doc',           # Bug #48863.
      'tree',                        # Bug #48862.
      'nodejs',
      'php5-curl',
      'mono-runtime',
      'php5-cli',
      'php5-mysql',
      'php5-redis',
      'libcache-memcached-fast-perl',
      'libhtml-parser-perl',
      'libwww-perl',
      'liburi-perl',
      'libjson-perl',
      'libjson-xs-perl',
      'libdbd-sqlite3-perl',
      'libpoe-perl',
      'python-twisted',
      'python-virtualenv',
      'libclass-data-inheritable-perl',
      'libcommon-sense-perl',
      'libcrypt-openssl-bignum-perl',
      'libcrypt-openssl-rsa-perl',
      'libdigest-hmac-perl',
      'libmediawiki-bot-perl',
      'libmediawiki-api-perl',
      'libpng3',
      'libfreetype6',
      'libmpc2',
      'libmpfr4',
      'libneon27-gnutls',
      'libnet-oauth-perl',
      'libnfnetlink0',
      'libnspr4',
      'libnss3',
      'libnss3-1d',
      'libotf0',
      'libpcsclite1',
      'libquadmath0',
      'libstring-diff-perl',
      'libstring-shellquote-perl',   # For jsub.
      'libsvn1',
      'mariadb-common',
      'openjdk-7-jre-headless',
      'python-apport',
      'python-flask',
      'python-flup',
      'python-gdbm',
      'python-gi',
      'python-httplib2',
      'python-keyring',
      'python-launchpadlib',
      'python-mysql.connector',
      'python-problem-report',
      'python-newt',
      'python-wadllib',
      'python-webpy',
      'python-werkzeug',
      'python-mysqldb',
      'python-requests',
      'python-redis',
      'python3',
      'mono-complete',
      'python-irclib',
      'adminbot',
      'gnuplot-nox',
      'libpod-simple-wiki-perl',
      'libxml-libxml-perl',
      'libdbd-mysql-perl',
      'libnetaddr-ip-perl',
      'tcl',
      'tclcurl',
      'tcllib',
      'ruby1.9.3',
      'libthreads-shared-perl',
      'libthreads-perl',
      'dc',
      'p7zip',
      'phpunit',
      'r-base' ]:
    ensure => present
  }

  sysctl { "vm.overcommit_memory": value => 2 }
  sysctl { "vm.overcommit_ratio": value => 95 }

  # TODO: quotas
}

