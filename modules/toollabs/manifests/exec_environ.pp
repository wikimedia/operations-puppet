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
      # Language Runtimes
      'openjdk-7-jre-headless',
      'python3',
      'nodejs',
      'mono-runtime',
      'tcl',
      'ruby1.9.3',
      'r-base',

      # Perl libraries
      'libdata-compare-perl',        # For Checkwiki.
      'libtest-exception-perl',      # For Checkwiki.
      'libxml-xpathengine-perl',     # For Checkwiki.
      'libcache-memcached-fast-perl',
      'libhtml-parser-perl',
      'libwww-perl',
      'liburi-perl',
      'libjson-perl',
      'libjson-xs-perl',
      'libdbd-sqlite3-perl',
      'libpoe-perl',
      'libclass-data-inheritable-perl',
      'libcommon-sense-perl',
      'libcrypt-openssl-bignum-perl',
      'libcrypt-openssl-rsa-perl',
      'libdigest-hmac-perl',
      'libmediawiki-bot-perl',
      'libmediawiki-api-perl',
      'libstring-diff-perl',
      'libstring-shellquote-perl',   # For jsub.
      'libpod-simple-wiki-perl',
      'libxml-libxml-perl',
      'libdbd-mysql-perl',
      'libnetaddr-ip-perl',
      'libthreads-shared-perl',
      'libthreads-perl',
      'libnet-oauth-perl',

      # Python libraries
      'python-genshi',               # Bug #48863.
      'python-genshi-doc',           # Bug #48863.
      'python-twisted',
      'python-virtualenv',
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
      'python-celery',
      'python-celery-with-redis',
      'python-flask-login',
      'python-flask-oauth',
      'python-nose',
      'python-sqlalchemy',
      'python-irclib',

      # PHP libraries
      'php5-curl',
      'php5-cli',
      'php5-mysql',
      'php5-redis',
      'php5-xsl',

      # Other packages
      'mariadb-client',              # For /usr/bin/mysql.
      'mariadb-common',
      'mdbtools',                    # Bug #48805.
      'tree',                        # Bug #48862.
      'libpng3',
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
      'libquadmath0',
      'libsvn1',
      'mono-complete',
      'adminbot',
      'gnuplot-nox',
      'tclcurl',
      'tcllib',
      'dc',
      'p7zip',
      'phpunit'
      ]:
    ensure => present
  }

  sysctl { "vm.overcommit_memory": value => 2 }
  sysctl { "vm.overcommit_ratio": value => 95 }

  # TODO: quotas
}

