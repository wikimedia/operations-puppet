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
      'libdbi-perl',
      'libdigest-crc-perl',
      'libdigest-hmac-perl',
      'libfile-nfslock-perl',
      'libhtml-html5-entities-perl',
      'libhtml-parser-perl',
      'libhttp-message-perl',
      'libimage-exiftool-perl',      # Bug #53868.
      'libio-socket-ssl-perl',
      'libipc-run-perl',
      'libirc-utils-perl',
      'libjson-perl',
      'libjson-xs-perl',
      'liblwp-protocol-https-perl',
      'libmediawiki-api-perl',
      'libmediawiki-bot-perl',
      'libnet-netmask-perl',
      'libnet-oauth-perl',
      'libnet-ssleay-perl',
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
      'libtime-local-perl',
      'libtimedate-perl',
      'liburi-encode-perl',
      'liburi-perl',
      'libwww-perl',
      'libxml-libxml-perl',
      'libxml-parser-perl',
      'libxml-simple-perl',
      'libxml-xpathengine-perl',     # For Checkwiki.

      # Python libraries
      'libboost-python1.48.0',
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
      'python-opencv',
      'python-oursql',               # For danilo et al.
      'python-problem-report',
      'python-redis',
      'python-requests',
      'python-rsvg',
      'python-scipy',
      'python-sqlalchemy',
      'python-twisted',
      'python-uwsgi',
      'python-virtualenv',
      'python-wadllib',
      'python-webpy',
      'python-werkzeug',
      'python-wikitools',
      'python-zmq',

      # PHP libraries
      'php5-cli',
      'php5-curl',
      'php5-gd',
      'php5-mcrypt',
      'php5-mysql',
      'php5-redis',
      'php5-sqlite',
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
      'fabric',                      # Bug #54135.
      'git',
      'gnuplot-nox',
      'graphviz',
      'libav-tools',                 # Bug #53870.
      'libdmtx0a',                   # Bug #53867.
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
      'poppler-utils',               # Bug #53869.
      'tree'                         # Bug #48862.
      ]:
    ensure => present
  }

  sysctl::parameters { 'tool labs':
    values => {
      'vm.overcommit_memory' => 2,
      'vm.overcommit_ratio'  => 95,
    },
  }

  # TODO: quotas
}

