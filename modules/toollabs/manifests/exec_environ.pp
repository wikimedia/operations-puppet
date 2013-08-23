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
      'golang',
      'luarocks',
      'mono-complete',
      'nodejs',
      'openjdk-7-jre-headless',
      'python3',
      'r-base',
      'ruby1.9.3',
      'tcl8.6',

      # Perl libraries
      'libbot-basicbot-perl',
      'libcache-memcached-fast-perl',
      'libclass-data-inheritable-perl',
      'libcommon-sense-perl',
      'libcrypt-gcrypt-perl',
      'libcrypt-openssl-bignum-perl',
      'libcrypt-openssl-rsa-perl',
      'libdata-compare-perl',        # For Checkwiki.
      'libdata-dumper-simple-perl',
      'libdatetime-format-duration-perl',
      'libdatetime-format-strptime-perl',
      'libdbd-mysql-perl',
      'libdbd-sqlite3-perl',
      'libdigest-crc-perl',
      'libdigest-hmac-perl',
      'libhtml-html5-entities-perl',
      'libhtml-parser-perl',
      'libirc-utils-perl',
      'libjson-perl',
      'libjson-xs-perl',
      'libmediawiki-api-perl',
      'libmediawiki-bot-perl',
      'libnet-oauth-perl',
      'libnetaddr-ip-perl',
      'libobject-pluggable-perl',
      'libpod-simple-wiki-perl',
      'libpoe-component-irc-perl',
      'libpoe-component-syndicator-perl',
      'libpoe-filter-ircd-perl',
      'libpoe-perl',
      'libredis-perl',
      'libsocket-getaddrinfo-perl',
      'libstring-diff-perl',
      'libstring-shellquote-perl',   # For jsub.
      'libtask-weaken-perl',
      'libtest-exception-perl',      # For Checkwiki.
      'libthreads-perl',
      'libthreads-shared-perl',
      'liburi-perl',
      'libwww-perl',
      'libxml-libxml-perl',
      'libxml-simple-perl',
      'libxml-xpathengine-perl',     # For Checkwiki.

      # Python libraries
      'python-apport',
      'python-beautifulsoup',        # For valhallasw.
      'python-celery',
      'python-celery-with-redis',
      'python-egenix-mxdatetime',
      'python-egenix-mxtools',
      'python-flask',
      'python-flask-login',
      'python-flask-oauth',
      'python-flup',
      'python-gdbm',
      'python-genshi',               # Bug #48863.
      'python-genshi-doc',           # Bug #48863.
      'python-gevent',
      'python-gi',
      'python-greenlet',
      'python-httplib2',
      'python-imaging',
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
      'python-uwsgi',
      'python-virtualenv',
      'python-wadllib',
      'python-webpy',
      'python-werkzeug',
      'python-zmq',

      # PHP libraries
      'php5-cli',
      'php5-curl',
      'php5-gd',
      'php5-mcrypt',
      'php5-mysql',
      'php5-redis',
      'php5-xsl',

      # tcl packages
      'mysqltcl',
      'tclcurl',
      'tcllib',
      'tclthread',

      # Other packages
      'adminbot',
      'csh',                        # common user request
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
      'libvips-tools',
      'libvips15',
      'mariadb-client',              # For /usr/bin/mysql.
      'mdbtools',                    # Bug #48805.
      'p7zip',
      'phpunit',
      'tree'                         # Bug #48862.
      ]:
    ensure => present
  }

  sysctlfile { "vm.overcommit_memory": value => 2 }
  sysctlfile { "vm.overcommit_ratio": value => 95 }

  # TODO: quotas
}

