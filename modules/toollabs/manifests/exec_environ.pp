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

        # Locales (Bug 58500)
        'language-pack-zh-hans',
        'language-pack-zh-hant',
        'language-pack-es',
        'language-pack-en',
        'language-pack-hi',
        'language-pack-ar',
        'language-pack-pt',
        'language-pack-bn',
        'language-pack-ru',
        'language-pack-ja',
        'language-pack-pa',
        'language-pack-de',
        'language-pack-fr',
        'language-pack-nl',
        'language-pack-he',

        # Language Runtimes
        'gcj-jre',                     # Bug 56995
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
        'libbsd-resource-perl',        # Bug 54690.
        'libcache-memcached-fast-perl',
        'libclass-data-inheritable-perl',
        'libcommon-sense-perl',
        'libcrypt-gcrypt-perl',
        'libcrypt-openssl-bignum-perl',
        'libcrypt-openssl-rsa-perl',
        'libberkeleydb-perl',          # Bug 58785
        'libdata-compare-perl',        # For Checkwiki.
        'libdata-dumper-simple-perl',
        'libdatetime-format-duration-perl',
        'libdatetime-format-strptime-perl',
        'libdbd-mysql-perl',
        'libdbd-sqlite2-perl',         # Bug 56995
        'libdbd-sqlite3-perl',
        'libdbi-perl',
        'libdigest-crc-perl',
        'libdigest-hmac-perl',
        'libfile-nfslock-perl',
        'libhtml-html5-entities-perl',
        'libhtml-parser-perl',
        'libhtml-template-perl',       # Bug 57123
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
        'libtext-diff-perl',           # Bug 58744
        'libthreads-perl',
        'libthreads-shared-perl',
        'libtime-local-perl',
        'libtimedate-perl',
        'liburi-encode-perl',
        'liburi-perl',
        'libwww-perl',
        'libwww-mechanize-perl',       # Bug 57118
        'libxml-libxml-perl',
        'libxml-parser-perl',
        'libxml-simple-perl',
        'libxml-xpathengine-perl',     # For Checkwiki.

        # Python libraries
        'libboost-python1.48.0',
        'python-apport',
        'python-babel',                # Bug 58220
        'python-beautifulsoup',        # For valhallasw.
        'python-bottle',               # Bug 56995
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
        'python-lxml',                 # Bug #59083.
        'python-mysql.connector',
        'python-mysqldb',
        'python-newt',
        'python-nose',
        'python-opencv',
        'python-oursql',               # For danilo et al.
        'python-problem-report',
        'python-pyinotify',            # Bug 57003
        'python-svn',                  # Bug 56996
        'python-rsvg',                 # Bug 56996
        'python-zbar',                 # Bug 56996
        'python-redis',
        'python-requests',
        'python-scipy',
        'python-sqlalchemy',
        'python-twitter',
        'python-twisted',
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
        'php5-intl',                   # Bug 55652
        'php5-mcrypt',
        'php5-mysql',
        'php5-redis',
        'php5-sqlite',
        'php5-xsl',

        # tcl packages
        'mysqltcl',
        'tcl-tls',                     # Bug 56995
        'tcl-trf',                     # Bug 56995
        'tclcurl',
        'tcllib',
        'tclthread',
        'tdom',                        # Bug 56995

        # Other packages
        'adminbot',
        'csh',                        # common user request
        'csvtool',                     # Bug 58649
        'dc',
        'djvulibre-bin',               # Bug 56972
        'djvulibre-plugin',            # Bug 56972
        'doxygen',                     # Bug 56326
        'doxygen-latex',               # Bug 56326
        'fabric',                      # Bug #54135.
        'git',
        'gnuplot-nox',
        'graphicsmagick',              # Bug 56995
        'graphviz',
        'ksh',
        'libav-tools',                 # Bug #53870.
        'libdmtx0a',                   # Bug #53867.
        'libfreetype6',
        'libgdal1-1.7.0',              # Bug 56995
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
        'libproj0',                    # Bug 56995
        'libprotobuf7',                # Bug 56995
        'libquadmath0',
        'librsvg2-bin',                # Bug 58516
        'libsvn1',
        'libvips-tools',
        'libvips15',
        'libzbar0',                    # Bug 56996
        'mariadb-client',              # For /usr/bin/mysql.
        'mdbtools',                    # Bug #48805.
        'socat',                       # Bug 57005
        'p7zip',
        'phpunit',
        'poppler-utils',               # Bug #53869.
        'pstoedit',                    # Bug 57000
        'pv',                          # Bug 57001
        'rrdtool',                     # Bug 57004
        'ufraw-batch',                 # Bug 57008
        'texinfo',                     # Bug #56994
        'tree',                        # Bug #48862.
        'zbar-tools',                  # Bug 56996
        'zsh',                         # Bug 56995
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

