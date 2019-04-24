# This class sets up a node as an execution environment for Toolforge.
# This is a "sub" role included by the actual Toolforge roles and would
# normally not be included directly in node definitions.
#
# Actual runtime dependencies for tools live here.
#

class profile::toolforge::grid::exec_environ {

    include ::profile::locales::extended
    # TODO: remove after oidentd has been deployed and pidentd cleaned up
    class { '::identd':
        ensure => absent,
    }
    class {'::redis::client::python': }

    apt::repository { "mono-external-${::lsbdistcodename}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/mono-project-${::lsbdistcodename}",
    }

    file { '/srv/composer':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    git::clone { 'composer':
        ensure             => 'latest',
        directory          => '/srv/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        recurse_submodules => true,
        require            => File['/srv/composer'],
    }

    # Create a symbolic link for the composer executable.
    file { '/usr/local/bin/composer':
        ensure  => 'link',
        target  => '/srv/composer/vendor/bin/composer',
        owner   => 'root',
        group   => 'root',
        require => Git::Clone['composer'],
    }

    # Packages in all OSs
    require_package(
        'fonts-arabeyes',
        'fonts-arphic-ukai',
        'fonts-arphic-uming',
        'fonts-farsiweb',
        'fonts-kacst',
        'fonts-khmeros',
        'fonts-lao',
        'fonts-liberation',
        'fonts-linuxlibertine',
        'fonts-manchufont',
        'fonts-nafees',
        'fonts-sil-abyssinica',
        'fonts-sil-ezra',
        'fonts-sil-padauk',
        'fonts-sil-scheherazade',
        'fonts-takao-gothic',
        'fonts-takao-mincho',
        'fonts-thai-tlwg',
        'fonts-tibetan-machine',
        'fonts-unfonts-core',
        'fonts-unfonts-extra',
        'texlive-fonts-recommended',
        'texlive-full',              # T197176
        'ttf-alee',
        'ttf-ubuntu-font-family',    # Not in Debian. T32288, T103325
        'ttf-wqy-zenhei',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-base',
        'xfonts-mplus',
        'xfonts-scalable',
        'fonts-sil-nuosusil',        # T83288
        'culmus',                    # T40946
        'culmus-fancy',              # T40946
        'fonts-lklug-sinhala',       # T57462
        'fonts-vlgothic',            # T66002
        'fonts-dejavu-core',         # T65206
        'fonts-dejavu-extra',        # T65206
        'fonts-lyx',                 # T40299
        'fonts-crosextra-carlito',   # T84842
        'fonts-crosextra-caladea',   # T84842
        'fonts-smc',                 # T33950
        'fonts-hosny-amiri',         # T135347
        'fonts-taml-tscu',           # T117919
        'pngquant',                  # T204422
        'qpdf',                      # T204422
        'unpaper',                   # T204422
    )

    if os_version('debian == jessie') {
        require_package(
            'fonts-noto', # T184664
            'sbt',
        )
    }

    if os_version('debian > jessie') {
        require_package(
            'fonts-noto-hinted',  # T184664
            'fonts-noto-unhinted' # T184664
        )
    }

    if os_version('debian >= jessie') {
        require_package(
            'fonts-beng',
            'fonts-deva',
            'fonts-gujr',
            'fonts-knda',
            'fonts-mlym',
            'fonts-orya',
            'fonts-guru',
            'fonts-taml',
            'fonts-telu',
            'fonts-gujr-extra',
            'fonts-noto-cjk',
            'fonts-sil-lateef',
            'fonts-ipafont-gothic',
            'fonts-ipafont-mincho',
        )
    }

    if $::operatingsystem == 'Ubuntu' {
      package { [
          # Please keep all packages in each group sorted in alphabetical order

          # Locales (T60500)
          'language-pack-ar',
          'language-pack-bn',
          'language-pack-ca',            # T64269, T68721
          'language-pack-de',
          'language-pack-en',
          'language-pack-es',
          'language-pack-eu',            # T183591
          'language-pack-fr',
          'language-pack-he',
          'language-pack-hi',
          'language-pack-ja',
          'language-pack-ko',            # T130532
          'language-pack-mr',            # T191727
          'language-pack-nl',
          'language-pack-pa',
          'language-pack-pt',
          'language-pack-ru',
          'language-pack-uk',            # T62730.
          'language-pack-zh-hans',
          'language-pack-zh-hant',

          # Language Runtimes and dev tools
          'ant',
          'autoconf',
          'automake',                    # T119870
          'build-essential',
          'bundler',                    # T120287
          'cmake',
          'cython',
          'gcj-jdk',                   # T58995
          'libdjvulibre-dev',          # T58972
          'libdmtx-dev',               # T55867.
          'libfcgi-dev',               # T54902.
          'libfreetype6-dev',
          'libgeoip-dev',              # T64649
          'libldap2-dev',              # T114388
          'libproj-dev',               # T58995
          'libprotobuf-dev',           # T58995
          'librsvg2-dev',              # T60516
          'libsasl2-dev',              # T114388
          'libsparsehash-dev',         # T58995
          'libssl-dev',                # T114388
          'libtool',
          'libvips-dev',
          'libxml2-dev',
          'libxslt1-dev',
          'libzbar-dev',               # T58996
          'maven',
          'mercurial',                 # T198008
          'subversion',
          'qt4-qmake',   # Isn't this very deprecated?
          'rake',                      # T120287
          'ruby-dev',                  # T120287
          'gcj-jre',                     # T58995
          'golang',
          'luarocks',
          'mono-complete',
          'mono-fastcgi-server',         # T85142
          'mono-vbnc',                   # T186846
          'npm',                         # T1102
          'nodejs',
          'openjdk-7-jre-headless',
          'icedtea-7-jre-jamvm',         # T98195
          # 'python3',                   # gerrit:411211
          'r-base',
          'ruby1.9.3',
          'tcl8.6',

          # Perl libraries
          'libberkeleydb-perl',          # T60785
          'libbot-basicbot-perl',
          'libbsd-resource-perl',        # T56690.
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
          'python-pymysql',              # T189052
          'python3-pymysql',             # T189052

          # PHP libraries
          'php5-cli',
          'php5-common',
          'php5-curl',
          'php5-gd',
          'php5-imagick',                # T71078.
          'php5-intl',                   # T57652
          'php5-mcrypt',
          'php5-mysqlnd',
          'php5-pgsql',                  # For access to OSM db
          'php5-redis',
          'php5-sqlite',
          'php5-xdebug',                 # T72313
          'php5-xhprof',                 # T179343
          'php5-xsl',

          # Fonts for vCat tool.
          'ttf-indic-fonts-core',        # Many Indic languages.

          # Fonts for latex
          'texlive-fonts-extra',        # T137121

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
          'inkscape',                    # T126933
          'ksh',
          'lame',                        # T168128
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
          'mktorrent',                   # T155470
          'openbabel',                   # T68995
          'p7zip-full',                  # requested by Betacommand and danilo to decompress 7z files
          'pdf2svg',                     # T70092.
          'pdf2djvu',                    # T130138
          'pdftk',                       # T67048.
          'phantomjs',                   # T68928
          'phpunit',
          'poppler-utils',               # T55869.
          'postgis',                     # T76226
          'postgresql-client',
          'pstoedit',                    # T59000
          'rrdtool',                     # T59004
          'socat',                       # T59005
          'sqlite3',                     # T196006
          'supybot',                     # T63088.
          'tabix',                       # T63501
          'texinfo',                     # T58994
          'texlive',
          'ufraw-batch',                 # T59008
          'virtualenvwrapper',           # T131840
          'whois',                       # T98555
          'xml2',                        # T134146.
          'xsltproc',                    # T68962.
          'xvfb',                        # T100268
          'zbar-tools',                  # T58996
          'debootstrap',                 # T138138
          'fakechroot',                  # T138138
          ]:
          ensure => latest,
          before => Class['::profile::locales::extended'],
      }
    } elsif $::operatingsystem == 'Debian' {
      package { [
          # Please keep all packages in each group sorted in alphabetical order
          # Locales (T60500)
          # language-packs not available in Debian
          # To add all locales, this needs to all be in a role so that the include
          # works

          # Language Runtimes and dev tools
          'ant',
          'autoconf',
          'automake',                    # T119870
          'build-essential',
          'bundler',                    # T120287
          'cmake',
          'cython',
          'gcj-jdk',                   # T58995
          'libdjvulibre-dev',          # T58972
          'libdmtx-dev',               # T55867.
          'libfcgi-dev',               # T54902.
          'libfreetype6-dev',
          'libgeoip-dev',              # T64649
          'libldap2-dev',              # T114388
          'libproj-dev',               # T58995
          'libprotobuf-dev',           # T58995
          'librsvg2-dev',              # T60516
          'libsasl2-dev',              # T114388
          'libsparsehash-dev',         # T58995
          'libssl-dev',                # T114388
          'libtool',
          'libvips-dev',
          'libxml2-dev',
          'libxslt1-dev',
          'libzbar-dev',               # T58996
          'maven',
          'mercurial',                 # T198008
          'subversion',
          'qt4-qmake',   # Isn't this very deprecated?
          'rake',                      # T120287
          'ruby-dev',                  # T120287
          'gcj-jre',                     # T58995
          'golang',
          'luarocks',
          'mono-complete',
          'mono-fastcgi-server',         # T85142
          'mono-vbnc',                   # T186846
          'r-base',
          'ruby',
          'tcl',

          # Perl libraries
          'libberkeleydb-perl',          # T60785
          'libbot-basicbot-perl',
          'libbsd-resource-perl',        # T56690.
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
          'libgd-perl',              # T69199.
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

          # Python libraries on apt.wm.o or tools apt repo
          # Other python package requirements are added
          # using the genpp tool
          # python-flask-oauth is not in Debian
          'python-mwparserfromhell',     # T65539
          # python-oursql is not in Debian
          'python-socketio-client',      # T86015
          #python-wikitools is apparently not in Debian (at least stretch)
          'python-mwclient',             # T218242
          'python-pymysql',              # T189052
          'python3-pymysql',             # T189052

          # Fonts for vCat tool.
          'fonts-indic',        # Many Indic languages.

          # Fonts for latex
          'texlive-fonts-extra',        # T137121

          # tcl packages
          'mysqltcl',
          'tcl-tls',                     # T58995
          'tcl-trf',                     # T58995
          'tclcurl',
          'tcllib',
          'tdom',                        # T58995

          # Other packages
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
          'inkscape',                    # T126933
          'ksh',
          'lame',                        # T168128
          'libaio1',                     # T70615
          'libav-tools',                 # T55870.
          'libdmtx0a',                   # T55867.
          'libexiv2-dev',                # T213965
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
          #libnss3-1d is not in stretch
          'libotf0',
          'libpcsclite1',
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
          'mktorrent',                   # T155470
          'openbabel',                   # T68995
          'p7zip-full',                  # requested by Betacommand and danilo to decompress 7z files
          'pdf2svg',                     # T70092.
          'pdf2djvu',                    # T130138
          'pdftk',                       # T67048.
          'phantomjs',                   # T68928
          'poppler-utils',               # T55869.
          'postgis',                     # T76226
          'postgresql-client',
          'pstoedit',                    # T59000
          'rrdtool',                     # T59004
          'socat',                       # T59005
          'sqlite3',                     # T196006
          'supybot',                     # T63088.
          'tabix',                       # T63501
          'texinfo',                     # T58994
          'texlive',
          'ufraw-batch',                 # T59008
          'virtualenvwrapper',           # T131840
          'whois',                       # T98555
          'xauth',                       # T215699
          'xml2',                        # T134146.
          'xsltproc',                    # T68962.
          'xvfb',                        # T100268
          'zbar-tools',                  # T58996
          'debootstrap',                 # T138138
          'fakechroot',                  # T138138
          ]:
          ensure => latest,
          before => Class['::profile::locales::extended'],
      }
    }

    file { '/etc/mysql/conf.d/override.my.cnf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/override.my.cnf',
    }

    if $::lsbdistcodename == 'jessie' {
        include ::profile::toolforge::genpp::python_exec_jessie
        # No obvious package available for libgdal
        package { [
            'hhvm',                        # T78783
            'libboost-python1.55.0',
            'libmpc3',
            'libproj0',
            'libprotobuf9',
            'libbytes-random-secure-perl', # T123824
            'libvips38',
            'nodejs',
            'nodejs-legacy',               # T1102
            'npm',
            'mariadb-client',              # For /usr/bin/mysql
            'openjdk-7-jre-headless',
            'libpng12-0',
            'perl-modules',
            'php5-cli',
            'php5-common',
            'php5-curl',
            'php5-gd',
            'php5-imagick',                # T71078.
            'php5-intl',                   # T57652
            'php5-mcrypt',
            'php5-mysqlnd',
            'php5-pgsql',                  # For access to OSM db
            'php5-redis',
            'php5-sqlite',
            'php5-xdebug',                 # T72313
            'php5-xhprof',                 # T179343
            'php5-xsl',
            'php5-readline',               # T136519.
            'opencv-data',                 # T142321
            'python-flake8',
            'python3-flake8',
            'tcl-thread',
            'libmariadb-client-lgpl-dev',
            'libmariadb-client-lgpl-dev-compat',
            'libboost-python1.55-dev',
            'openjdk-7-jdk',
            'libpng12-dev',
            'libtiff4-dev', # T54717
            'tcl8.5-dev',
            'libgdal1-dev',                # T58995
            ]:
            ensure => latest,
        }
    } elsif $::lsbdistcodename == 'stretch' {
        include ::profile::toolforge::genpp::python_exec_stretch
        apt::repository { "php72-external-${::lsbdistcodename}": #T213666
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/php72',
        }

        # T212981 - installing npm requires some extra love
        $nodejs_packages = [
            'nodejs',
            'nodejs-dev',
        ]

        apt::pin { $nodejs_packages:
            pin      => 'release a=stretch-backports',
            priority => '2000',
            before   => Package['nodejs'],
        }

        package { [
            'npm',
            'nodejs',
            'node-cacache',
            'node-move-concurrently',
            'node-gyp',
            'nodejs-dev',
            ]:
            ensure          => latest,
            install_options => ['-t', 'stretch-backports'],
        }

        # T67354, T215693 - Tesseract OCR from stretch-backports
        $tesseract_packages = [
            'tesseract-ocr-all'
        ]
        apt::pin { $tesseract_packages:
            pin      => 'release a=stretch-backports',
            priority => '2000',
            before   => Package[$tesseract_packages],
        }
        package { $tesseract_packages:
            ensure          => latest,
            install_options => ['-t', 'stretch-backports'],
        }

        package { [
            'hhvm',                         # T78783
            'libboost-python-dev',          # T213965
            'libmpc3',
            'libproj12',
            'libprotobuf10',
            'libbytes-random-secure-perl', # T123824
            'libvips42',
            'mariadb-client',              # For /usr/bin/mysql
            'libpng16-16',
            'perl-modules-5.24',
            # PHP libraries (Stretch is on php7)
            'php-apcu',
            'php-apcu-bc',
            'php7.2-bcmath',
            'php7.2-bz2',
            'php7.2-cli',
            'php7.2-common',
            'php7.2-curl',
            'php7.2-dba',
            'php7.2-gd',
            'php-imagick',                # T71078.
            'php7.2-intl',                   # T57652
            'php7.2-mbstring',
            # php-mcrypt is deprecated on 7.1+
            'php7.2-mysql',
            'php7.2-pgsql',                  # For access to OSM db
            'php7.2-readline',               # T136519.
            'php-redis',
            'php7.2-soap',
            'php7.2-sqlite3',
            'php-xdebug',                 # T72313
            # php-xhprof isn't available in stretch
            'php7.2-xml',
            'php7.2-zip',
            'opencv-data',                 # T142321
            'openjdk-11-jre-headless',
            'tcl-thread',
            'libmariadbclient-dev',
            'libmariadbclient-dev-compat',
            'libboost1.62-dev',
            'libboost-dev',
            'libkml-dev',
            'libgdal-dev',                # T58995
            'libboost-python1.62-dev',
            'openjdk-11-jdk',
            'libpng-dev',
            'libtiff5-dev',  # T54717
            'tcl-dev',
          ]:
          ensure => latest,
        }
    }

    # misctools is in the aptly repo -- need to build that stuff for stretch
    package { 'misctools':
        ensure => latest,
    }

    sysctl::parameters { 'toolforge':
        values => {
            'vm.overcommit_memory' => 2,
            'vm.overcommit_ratio'  => 95,
        },
    }

    # The hhvm deb starts a demon process automatically that we don't need
    # running.
    service { 'hhvm':
        ensure  => 'stopped',
        require => Package['hhvm'],
    }


    # T65000
    require_package('imagemagick')
    require_package('webp')

    if os_version('debian >= jessie') {
        # configuration directory changed since ImageMagick 8:6.8.5.6-1
        $confdir = '/etc/ImageMagick-6'
    } else {
        $confdir = '/etc/ImageMagick'
    }

    file { "${confdir}/policy.xml":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/imagemagick/policy.xml',
        require => [
            Class['packages::imagemagick'],
            Class['packages::webp']
        ]
    }
}
