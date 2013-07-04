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
      # Please keep all packages in each group sorted in alphabetical order

      # Language Runtimes
      'mono-runtime',
      'nodejs',
      'openjdk-7-jre-headless',
      'python3',
      'r-base',
      'ruby1.9.3',
      'tcl',

      # Perl libraries
      'libcache-memcached-fast-perl',
      'libclass-data-inheritable-perl',
      'libcommon-sense-perl',
      'libcrypt-openssl-bignum-perl',
      'libcrypt-openssl-rsa-perl',
      'libdata-compare-perl',        # For Checkwiki.
      'libdbd-mysql-perl',
      'libdbd-sqlite3-perl',
      'libdigest-hmac-perl',
      'libhtml-parser-perl',
      'libjson-perl',
      'libjson-xs-perl',
      'libmediawiki-api-perl',
      'libmediawiki-bot-perl',
      'libnet-oauth-perl',
      'libnetaddr-ip-perl',
      'libpod-simple-wiki-perl',
      'libpoe-perl',
      'libstring-diff-perl',
      'libstring-shellquote-perl',   # For jsub.
      'libtest-exception-perl',      # For Checkwiki.
      'libthreads-perl',
      'libthreads-shared-perl',
      'liburi-perl',
      'libwww-perl',
      'libxml-libxml-perl',
      'libxml-xpathengine-perl',     # For Checkwiki.

      # Python libraries
      'python-apport',
      'python-celery',
      'python-celery-with-redis',
      'python-flask',
      'python-flask-login',
      'python-flask-oauth',
      'python-flup',
      'python-gdbm',
      'python-genshi',               # Bug #48863.
      'python-genshi-doc',           # Bug #48863.
      'python-gi',
      'python-httplib2',
      'python-irclib',
      'python-keyring',
      'python-launchpadlib',
      'python-mysql.connector',
      'python-mysqldb',
      'python-newt',
      'python-nose',
      'python-problem-report',
      'python-redis',
      'python-requests',
      'python-sqlalchemy',
      'python-twisted',
      'python-virtualenv',
      'python-wadllib',
      'python-webpy',
      'python-werkzeug',

      # PHP libraries
      'php5-cli',
      'php5-curl',
      'php5-mysql',
      'php5-redis',
      'php5-xsl',

      # Other packages
      'adminbot',
      'dc',
      'gnuplot-nox',
      'libfreetype6',
      'libmpc2',
      'libmpfr4',
      'libneon27-gnutls',
      'libnfnetlink0',
      'libnspr4',
      'libnss3',
      'libnss3-1d',
      'libotf0',
      'libpcsclite1',
      'libpng3',
      'libquadmath0',
      'libsvn1',
      'mariadb-client',              # For /usr/bin/mysql.
      'mariadb-common',
      'mdbtools',                    # Bug #48805.
      'mono-complete',
      'p7zip',
      'phpunit',
      'tclcurl',
      'tcllib',
      'tree'                         # Bug #48862.
      ]:
    ensure => present
  }

  sysctl { "vm.overcommit_memory": value => 2 }
  sysctl { "vm.overcommit_ratio": value => 95 }

  # TODO: quotas
}

