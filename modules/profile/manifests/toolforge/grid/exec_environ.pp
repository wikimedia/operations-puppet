# This class sets up a node as an execution environment for Toolforge.
# This is a "sub" role included by the actual Toolforge roles and would
# normally not be included directly in node definitions.
#
# Actual runtime dependencies for tools live here.
#

class profile::toolforge::grid::exec_environ {

    include profile::locales::all

    class {'redis::client::python': }
    class {'phabricator::arcanist': }  # T139738 and T287390

    if debian::codename::eq('stretch') {
        # we use default buster mono version in the buster grid
        apt::repository { "mono-external-${::lsbdistcodename}":
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => "thirdparty/mono-project-${::lsbdistcodename}",
        }
    }

    if debian::codename::ge('buster') {
        ensure_packages(['composer'])

        file { '/srv/composer':
            ensure => absent,
            force  => true,
        }

        file { '/usr/local/bin/composer':
            ensure => absent,
        }
    } else {
        file { '/srv/composer':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }

        git::clone { 'composer':
            ensure             => 'latest',
            directory          => '/srv/composer',
            origin             => 'https://gerrit.wikimedia.org/r/integration/composer.git',
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
    }

    # Packages in all OSs
    ensure_packages([
        'fish',                      # T219054, T241290
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
        'fonts-alee',
        'fonts-wqy-zenhei',
        'xfonts-100dpi',
        'xfonts-75dpi',
        'xfonts-base',
        'xfonts-mplus',
        'xfonts-scalable',
        'fonts-sil-nuosusil',        # T83288
        'culmus',                    # T40946
        'culmus-fancy',              # T40946
        'fdm',                       # T297683
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
        'zstd',                      # T225380
        'fonts-noto-hinted',  # T184664
        'fonts-noto-unhinted', # T184664
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
    ])

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
        'clang',                     # T300469
        'cmake',
        'cython',
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
        'golang',
        'luarocks',
        'mono-complete',
        'mono-fastcgi-server',         # T85142
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
        'libfile-slurp-perl',      # T305308
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
        'liblocale-codes-perl',  # T307812
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
        'libxml-feed-perl',            # T256734
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
        'libexiv2-dev',                # T213965
        'libfcgi0ldbl',                # T58995
        'libffi-dev',                  # T67974.
        'libfreetype6',
        'libgdbm-dev',                 # T67974.
        'libgeoip1',                   # T64649
        'libhunspell-dev',             # T125193
        'libjpeg-turbo-progs',         # T61654.
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
        'pandoc',                      # T279787
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
        before => Class['profile::locales::all'],
    }

    file { '/etc/mysql/conf.d/override.my.cnf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/override.my.cnf',
    }

    # misctools is in the aptly repo -- need to build that stuff for stretch
    package { 'misctools':
        ensure => latest,
    }

    # T65000
    ensure_packages(['imagemagick', 'webp'])

    file { '/etc/ImageMagick-6/policy.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/imagemagick/policy.xml',
        require => Package['imagemagick', 'webp'],
    }

    # Distro specific bits
    require "profile::toolforge::grid::exec_environ::${::lsbdistcodename}"
}
