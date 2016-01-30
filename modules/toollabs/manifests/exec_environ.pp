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
    include locales::extended
    include identd
    include ::mediawiki::packages::fonts
    include ::redis::client::python

    package { [
        # Please keep all packages in each group sorted in alphabetical order

        # Locales (T60500)
        'language-pack-ar',
        'language-pack-bn',
        'language-pack-ca',            # T64269, T68721
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
        'language-pack-uk',            # T62730.
        'language-pack-zh-hans',
        'language-pack-zh-hant',

        # Language Runtimes
        'gcj-jre',                     # T58995
        'golang',
        'luarocks',
        'mono-complete',
        'mono-fastcgi-server',         # T85142
        'npm',                         # T1102
        'nodejs',
        'openjdk-7-jre-headless',
        'icedtea-7-jre-jamvm',         # T98195
        'python3',
        'r-base',
        'ruby1.9.3',
        'tcl8.6',

        # Perl libraries
        'libberkeleydb-perl',          # T60785
        'libbot-basicbot-perl',
        'libbsd-resource-perl',        # T56690.
        'libbytes-random-secure-perl', # T123824
        'libcache-memcached-fast-perl',
        'libcgi-fast-perl',            # T70269.
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
        'libdbd-sqlite2-perl',         # T58995
        'libdbd-sqlite3-perl',
        'libdbi-perl',
        'libdigest-crc-perl',
        'libdigest-hmac-perl',
        'libfile-nfslock-perl',
        'libgd-gd2-perl',              # T69199.
        'libhtml-format-perl',
        'libhtml-html5-entities-perl',
        'libhtml-parser-perl',
        'libhtml-template-perl',       # T59123
        'libhttp-message-perl',
        'libimage-exiftool-perl',      # T55868.
        'libio-socket-ssl-perl',
        'libipc-run-perl',
        'libirc-utils-perl',
        'libjson-perl',
        'libjson-xs-perl',
        'liblog-log4perl-perl',        # T76974
        'liblwp-protocol-https-perl',
        'libmediawiki-api-perl',
        'libmediawiki-bot-perl',
        'libnet-netmask-perl',
        'libnet-oauth-perl',
        'libnet-ssleay-perl',
        'libnetaddr-ip-perl',
        'libobject-pluggable-perl',
        'libparse-mediawikidump-perl', # T76976
        'libpod-simple-wiki-perl',
        'libpoe-component-irc-perl',
        'libpoe-component-syndicator-perl',
        'libpoe-filter-ircd-perl',
        'libpoe-perl',
        'libppix-regexp-perl',         # T76974
        'libreadonly-perl',            # T76974
        'libredis-perl',
        'libregexp-common-perl',       # T76974
        'libsocket-getaddrinfo-perl',
        'libsort-fields-perl',         # T116579
        'libstring-diff-perl',
        'libtask-weaken-perl',
        'libtest-exception-perl',      # For Checkwiki.
        'libtext-diff-perl',           # T60744
        'libtimedate-perl',
        'liburi-encode-perl',
        'liburi-perl',
        'libwww-mechanize-perl',       # T59118
        'libwww-perl',
        'libxml-libxml-perl',
        'libxml-parser-perl',
        'libxml-simple-perl',
        'libxml-xpathengine-perl',     # For Checkwiki.
        'perl-modules',

        # Python libraries on apt.wm.o or tools apt repo
        # Other python package requirements are added
        # using the genpp tool
        'python-flask-oauth',
        'python-mwparserfromhell',     # T65539
        'python-oursql',               # For danilo et al.
        'python-socketio-client',      # T86015
        'python-wikitools',
        'python-mwclient',             # for morebots et al

        # PHP libraries
        'php5-cli',
        'php5-curl',
        'php5-gd',
        'php5-imagick',                # T71078.
        'php5-intl',                   # T57652
        'php5-mcrypt',
        'php5-mysql',
        'php5-pgsql',                  # For access to OSM db
        'php5-redis',
        'php5-sqlite',
        'php5-xdebug',                 # T72313
        'php5-xsl',

        # Fonts for vCat tool.
        'fonts-ipafont-gothic',        # Japanese fonts.
        'ttf-indic-fonts',             # Many Indic languages.

        # tcl packages
        'mysqltcl',
        'tcl-tls',                     # T58995
        'tcl-trf',                     # T58995
        'tclcurl',
        'tcllib',
        'tdom',                        # T58995

        # Tesseract OCR (T67354).
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
        'bison',                       # T67974.
        'calibre',                     # T100165
        'csh',                         # common user request
        'csvtool',                     # T60649
        'dc',
        'djvulibre-bin',               # T58972
        'djvulibre-plugin',            # T58972
        'doxygen',                     # T58326
        'doxygen-latex',               # T58326
        'expect',
        'fabric',                      # T56135.
        'gawk',                        # T67974.
        'gdal-bin',
        'git-review',                  # T64871.
        'git-svn',
        'gnuplot-nox',
        'graphicsmagick',              # T58995
        'graphviz',
        'grep',
        'hugin-tools',                 # T108210
        'hunspell',                    # T125193
        'imagemagick',                 # T65000
        'iotop',                       # useful for labs admins to monitor tools
        'ksh',
        'libaio1',                     # T70615
        'libav-tools',                 # T55870.
        'libdmtx0a',                   # T55867.
        'libfcgi0ldbl',                # T58995
        'libffi-dev',                  # T67974.
        'libfreetype6',
        'libgdbm-dev',                 # T67974.
        'libgeoip1',                   # T64649
        'libhunspell-dev',             # T125193
        'libjpeg-turbo-progs',         # T61654.
        'libmpfr4',
        'libncurses5-dev',             # T67974.
        'libneon27-gnutls',
        'libnfnetlink0',
        'libnspr4',
        'libnss3',
        'libnss3-1d',
        'libotf0',
        'libpcsclite1',
        'libpng3',
        'libproj0',                    # T58995
        'libquadmath0',
        'librsvg2-bin',                # T60516
        'libsvn1',
        'libvips-tools',
        'libxml2-utils',               # T64944.
        'libyaml-dev',                 # T67974.
        'libzbar0',                    # T58996
        'mailutils',                   # T114073
        'mdbtools',                    # T50805.
        'melt',                        # T71365
        'openbabel',                   # T68995
        'p7zip-full',                  # requested by Betacommand and danilo to decompress 7z files
        'pdf2svg',                     # T70092.
        'pdftk',                       # T67048.
        'phantomjs',                   # T68928
        'phpunit',
        'poppler-utils',               # T55869.
        'postgis',                     # T76226
        'postgresql-client',
        'pstoedit',                    # T59000
        'rrdtool',                     # T59004
        'socat',                       # T59005
        'supybot',                     # T63088.
        'tabix',                       # T63501
        'texinfo',                     # T58994
        'texlive',
        'ufraw-batch',                 # T59008
        'whois',                       # T98555
        'xsltproc',                    # T68962.
        'xvfb',                        # T100268
        'zbar-tools',                  # T58996
        'zsh',                         # T58995
        ]:
        ensure => latest,
    }

    file { '/etc/mysql/conf.d/override.my.cnf':
        ensure => file,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/override.my.cnf',
    }

    # Packages that are different between precise and trusty go here.
    # Note: Every package *must* have equivalent package in both the
    # branches. If one is unavailable, please mark it as such with a comment.
    if $::lsbdistcodename == 'precise' {
        include toollabs::genpp::python_exec_precise
        package { [
            'libboost-python1.48.0',
            'libgdal1-1.7.0',              # T58995
            'libmpc2',
            'libprotobuf7',                # T58995
            'libtime-local-perl',          # now part of perl-modules
            'libthreads-shared-perl',      # now part of perl
            'libthreads-perl',             # now part of perl
            'libvips15',
            'mysql-client',                # mariadb-client just... doesn't work on precise. Apt failures
            'pyflakes',                    # T59863
            'tclthread',                   # now called tcl-thread
            # no nodejs-legacy             (presumably, -legacy makes a symlink that is default in precise)
            ]:
            ensure => latest,
        }
    } elsif $::lsbdistcodename == 'trusty' {
        include toollabs::genpp::python_exec_trusty
        # No obvious package available for libgdal
        package { [
            'hhvm',                        # T78783
            'libboost-python1.54.0',
            'libmpc3',
            'libprotobuf8',
            'libvips37',
            'nodejs-legacy',               # T1102
            'mariadb-client',              # For /usr/bin/mysql, is broken on precise atm
            'python-flake8',
            'python3-flake8',
            'tcl-thread',
            ]:
            ensure => latest,
        }
    } elsif $::lsbdistcodename == 'jessie' {
        include toollabs::genpp::python_exec_jessie
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

    package { 'misctools':
        ensure => latest,
    }

  # TODO: quotas
}
