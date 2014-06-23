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
        'language-pack-ar',
        'language-pack-bn',
        'language-pack-ca',            # Bugs #62269, #66721.
        'language-pack-de',
        'language-pack-en',
        'language-pack-es',
        'language-pack-fr',
        'language-pack-he',
        'language-pack-hi',
        'language-pack-ja',
        'language-pack-nl',
        'language-pack-pa',
        'language-pack-pt',
        'language-pack-ru',
        'language-pack-uk',            # Bug 60730.
        'language-pack-zh-hans',
        'language-pack-zh-hant',

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
        'libhtml-format-perl',
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
        'python-geoip',                # Bug 62649
        'python-gevent',
        'python-gi',
        'python-greenlet',
        'python-httplib2',
        'python-imaging',
        'python-irclib',
        'python-keyring',
        'python-launchpadlib',
        'python-lxml',                 # Bug #59083.
        'python-magic',                # Bug #60211.
        'python-matplotlib',           # Bug #61445.
        'python-mwparserfromhell',     # Bug #63539
        'python-mysql.connector',
        'python-mysqldb',
        'python-newt',
        'python-nose',
        'python-opencv',
        'python-oursql',               # For danilo et al.
        'python-problem-report',
        'python-pyexiv2',              # Bug 59122.
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
        'php5-pgsql',                  # For access to OSM db
        'php5-redis',
        'php5-sqlite',
        'php5-xsl',

        # Fonts
        'fonts-ipafont-gothic',        # for vCat tool (Japanese fonts)
        'fonts-unfonts-core',          # for vCat tool (Korean fonts)
        'ttf-indic-fonts',             # for vCat tool (fonts for many Indic languages)

        # tcl packages
        'mysqltcl',
        'tcl-tls',                     # Bug 56995
        'tcl-trf',                     # Bug 56995
        'tclcurl',
        'tcllib',
        'tclthread',
        'tdom',                        # Bug 56995

        # Tesseract OCR (bug #65354).
        'tesseract-ocr',
        'tesseract-ocr-afr',
        'tesseract-ocr-ara',
        'tesseract-ocr-aze',
        'tesseract-ocr-bel',
        'tesseract-ocr-ben',
        'tesseract-ocr-bul',
        'tesseract-ocr-cat',
        'tesseract-ocr-ces',
        'tesseract-ocr-chi-sim',
        'tesseract-ocr-chi-tra',
        'tesseract-ocr-chr',
        'tesseract-ocr-dan',
        'tesseract-ocr-deu',
        'tesseract-ocr-deu-frak',
        'tesseract-ocr-ell',
        'tesseract-ocr-eng',
        'tesseract-ocr-enm',
        'tesseract-ocr-epo',
        'tesseract-ocr-equ',
        'tesseract-ocr-est',
        'tesseract-ocr-eus',
        'tesseract-ocr-fin',
        'tesseract-ocr-fra',
        'tesseract-ocr-frk',
        'tesseract-ocr-frm',
        'tesseract-ocr-glg',
        'tesseract-ocr-heb',
        'tesseract-ocr-hin',
        'tesseract-ocr-hrv',
        'tesseract-ocr-hun',
        'tesseract-ocr-ind',
        'tesseract-ocr-isl',
        'tesseract-ocr-ita',
        'tesseract-ocr-ita-old',
        'tesseract-ocr-jpn',
        'tesseract-ocr-kan',
        'tesseract-ocr-kor',
        'tesseract-ocr-lav',
        'tesseract-ocr-lit',
        'tesseract-ocr-mal',
        'tesseract-ocr-mkd',
        'tesseract-ocr-mlt',
        'tesseract-ocr-msa',
        'tesseract-ocr-nld',
        'tesseract-ocr-nor',
        'tesseract-ocr-osd',
        'tesseract-ocr-pol',
        'tesseract-ocr-por',
        'tesseract-ocr-ron',
        'tesseract-ocr-rus',
        'tesseract-ocr-slk',
        'tesseract-ocr-slk-frak',
        'tesseract-ocr-slv',
        'tesseract-ocr-spa',
        'tesseract-ocr-spa-old',
        'tesseract-ocr-sqi',
        'tesseract-ocr-srp',
        'tesseract-ocr-swa',
        'tesseract-ocr-swe',
        'tesseract-ocr-tam',
        'tesseract-ocr-tel',
        'tesseract-ocr-tgl',
        'tesseract-ocr-tha',
        'tesseract-ocr-tur',
        'tesseract-ocr-ukr',
        'tesseract-ocr-vie',

        # Other packages
        'adminbot',
        'csh',                        # common user request
        'csvtool',                     # Bug 58649
        'dc',
        'djvulibre-bin',               # Bug 56972
        'djvulibre-plugin',            # Bug 56972
        'doxygen',                     # Bug 56326
        'doxygen-latex',               # Bug 56326
        'expect',
        'fabric',                      # Bug #54135.
        'gdal-bin',
        'git',
        'git-review',                  # Bug 62871.
        'git-svn',
        'gnuplot-nox',
        'graphicsmagick',              # Bug 56995
        'graphviz',
        'imagemagick',                 # Bug 63000
        'jq',                          # Bug #65049.
        'ksh',
        'iotop',                       # useful for labs admins to monitor tools
        'libav-tools',                 # Bug #53870.
        'libdmtx0a',                   # Bug #53867.
        'libfcgi0ldbl',                # Bug 56995
        'libfreetype6',
        'libgdal1-1.7.0',              # Bug 56995
        'libgeoip1',                   # Bug 62649
        'libjpeg-turbo-progs',         # Bug 59654.
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
        'libxml2-utils',               # Bug 62944.
        'libzbar0',                    # Bug 56996
        'mariadb-client',              # For /usr/bin/mysql.
        'mdbtools',                    # Bug #48805.
        'openbabel',                   # Bug #66995
        'socat',                       # Bug 57005
        'supybot',                     # Bug 61088.
        'p7zip',
        'pdftk',                       # Bug #65048.
        'phantomjs',                   # Bug #66928
        'phpunit',
        'poppler-utils',               # Bug #53869.
        'postgresql-client-9.1',
        'pstoedit',                    # Bug 57000
        'pv',                          # Bug 57001
        'rrdtool',                     # Bug 57004
        'ufraw-batch',                 # Bug 57008
        'tabix',                       # Bug 61501
        'texinfo',                     # Bug #56994
        'xsltproc',                    # Bug #66962.
        'zbar-tools',                  # Bug 56996
        'zsh',                         # Bug 56995
        ]:
        ensure => latest,
    }

    sysctl::parameters { 'tool labs':
        values => {
            'vm.overcommit_memory' => 2,
            'vm.overcommit_ratio'  => 95,
        },
    }

    file { '/usr/bin/sql':
        ensure => file,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/sql',
    }

  # TODO: quotas
}
