# == Class profile::analytics::cluster::packages::statistics
#
# Specific packages that should be installed on analytics statistics
# nodes (no Hadoop client related packages).
#
# If the stat node need to be capable of using Hadoop, please also include
# profile::analytics::cluster::packages::hadoop
#
class profile::analytics::cluster::packages::statistics {

    include ::profile::analytics::cluster::packages::common

    class { '::imagemagick::install': }

    require_package([
        'openjdk-8-jdk',
        'time',
        'emacs',
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'subversion',
        'mercurial',
        'tofrodos',
        'git-review',
        'make',                   # halfak wants make to manage dependencies
        'libwww-perl',            # For wikistats stuff
        'libcgi-pm-perl',         # For wikistats stuff
        'libjson-perl',           # For wikistats stuff
        'libtext-csv-xs-perl',    # T199131
        'sqlite3',                # For storing and interacting with intermediate results
        'libproj-dev',            # Requested by lzia for rgdal
        'libbz2-dev',             # for compiling some python libs. T84378
        'libboost-regex-dev',     # Ironholds wants these
        'libboost-system-dev',
        'libgoogle-glog-dev',
        'libboost-iostreams-dev',
        'libmaxminddb-dev',
        'build-essential',        # Requested by halfak to install SciPy
        'nodejs',
        'openjdk-8-jdk',
        'libssl-dev',             # Requested by bearloga; necessary for an essential R package (openssl)
        'libcurl4-openssl-dev',   # Requested by bearloga for an essential R package (devtools)
        'libicu-dev',             # ^
        'libssh2-1-dev',          # ^
        'pandoc',                 # Requested by bearloga; necessary for using RMarkdown and performing format conversions
        'lynx',                   # Requested by dcausse to be able to inspect yarn's logs from analytics10XX hosts
        'libgsl2',
        'gsl-bin',
        'libgsl-dev',
        'libgdal-dev',      # Requested by lzia for rgdal
        'g++',
        'libyaml-cpp-dev',  # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
        'libyaml-cpp0.5v5', # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
        'php-cli',
        'php-curl',
        'php-mysql',
        'mariadb-client-10.1',
    ])

    # Python packages
    require_package ([
        'virtualenv',
        'libapache2-mod-python',
        'python-mysqldb',               'python3-mysqldb',
        'python-boto',                  'python3-boto',  # Amazon S3 access (to get zero sms logs)
        'python-ua-parser',             'python3-ua-parser',
        'python-netaddr',               'python3-netaddr',
        'python-pymysql',               'python3-pymysql',
        'python-virtualenv',            'python3-virtualenv', # T84378
        'python-dev',                   'python3-dev',        # T83316
        'python-protobuf',              'python3-protobuf',
        'python-unidecode',             'python3-unidecode',
        # WMF maintains python-google-api at
        # https://gerrit.wikimedia.org/r/#/admin/projects/operations/debs/python-google-api
        'python-google-api',            'python3-google-api',           # T190767
        'python-oauth2client',          'python3-oauth2client',         # T197896
        'python-oauthlib',              'python3-oauthlib',             # T197896
        'python-requests-oauthlib',     'python3-requests-oauthlib',    # T197896
    ])

    # FORTRAN packages (T89414)
    require_package([
        'gfortran',        # GNU Fortran 95 compiler
        'liblapack-dev',   # FORTRAN library of linear algebra routines
        'libopenblas-dev', # Optimized BLAS (linear algebra) library
    ])

    # Plotting packages
    require_package([
        'ploticus',
        'libploticus0',
        'libcairo2',
        'libcairo2-dev',
        'libxt-dev',
    ])

    # Dictionary packages
    require_package([
        'enchant', # generic spell checking library (uses myspell as backend)
        'aspell-id',   # Indonesian dictionary for GNU aspell
        'hunspell-vi', # Vietnamese dictionary for hunspell
        'myspell-af', # Afrikaans dictionary for myspell
        'myspell-bg', # Bulgarian dictionary for myspell
        'myspell-ca', # Catalan dictionary for myspell
        'myspell-cs', # Czech dictionary for myspell
        # 'myspell-da', # The Comprehensive Danish Dictionary (DSDO) # conflicts with hunspell-vi
        'myspell-de-at', # Austrian (German) dictionary for myspell
        'myspell-de-ch', # Swiss (German) dictionary for myspell
        'myspell-de-de', # German dictionary for myspell
        'myspell-el-gr', # Greek (el_GR) dictionary for myspell
        'myspell-en-au', # English_australian dictionary for myspell
        'myspell-en-gb', # English_british dictionary for myspell
        'hunspell-en-us', # English_american dictionary for myspell
        'myspell-en-za', # English_southafrican dictionary for myspell
        'myspell-eo', # Esperanto dictionary for myspell
        'myspell-es', # Spanish dictionary for myspell
        'myspell-et', # Estonian dictionary for MySpell
        'myspell-fa', # Persian (Farsi) dictionary for myspell
        'myspell-fo', # Faroese dictionary for myspell
        'myspell-fr', # French dictionary for myspell (Hydro-Quebec version)
        'myspell-ga', # Irish (Gaeilge) dictionary for OpenOffice and Mozilla
        'myspell-gd', # Scots Gaelic dictionary for myspell
        'myspell-gv', # Manx Gaelic dictionary for myspell
        'myspell-he', # Hebrew dictionary for myspell
        'myspell-hr', # Croatian dictionary for myspell
        'myspell-hu', # Hungarian dictionary for myspell
        'myspell-hy', # Armenian dictionary for myspell
        'myspell-it', # Italian dictionary for myspell
        'myspell-ku', # Kurdish (Kurmanji) dictionary for myspell
        'myspell-lt', # myspell dictionary for Lithuanian (LT)
        'myspell-lv', # Latvian dictionary for Myspell
        'myspell-nb', # Norwegian Bokmal dictionary for myspell
        'myspell-nl', # Dutch dictionary for Hunspell
        'myspell-nn', # Norwegian Nynorsk dictionary for myspell
        'myspell-pl', # Polish dictionary for myspell
        'myspell-pt-br', # Brazilian Portuguese dictionary for myspell
        'myspell-pt', # Portuguese dictionaries for myspell
        'myspell-pt-pt', # European Portuguese dictionary for myspell
        'myspell-ru', # Russian dictionary for MySpell
        'myspell-sk', # Slovak dictionary for myspell
        'myspell-sl', # Slovenian dictionary for myspell
        'myspell-sv-se', # transitional dummy package
        'myspell-sw', # Swahili dictionary for myspell
        'myspell-th', # Thai dictionary for myspell
        'myspell-tl', # Tagalog dictionary for myspell/hunspell
        'myspell-uk', # Ukrainian dictionary for myspell
    ])

    # These are not available in Debian Stretch (I guess Ubuntu Trusty has more langs).
    # 'myspell-nr', # The Ndebele dictionary for myspell
    # 'myspell-ns', # Northern Sotho dictionary for myspell
    # 'myspell-ss', # The Swazi dictionary for myspell
    # 'myspell-st', # The Southern Sotho dictionary for myspell
    # 'myspell-tn', # The Tswana dictionary for myspell
    # 'myspell-ts', # The Tsonga dictionary for myspell
    # 'myspell-ve', # The Venda dictionary for myspell
    # 'myspell-xh', # The Xhosa dictionary for myspell
    # 'myspell-zu', # The Zulu dictionary for myspell


    # T214089
    if os_version('debian == stretch') {
        apt::pin { 'git-lfs':
            pin      => 'release a=stretch-backports',
            package  => 'git-lfs',
            priority => '1001',
            before   => Package['git-lfs'],
        }
    }

    # scap also deploys git-lfs to clients, so guarding
    # the package resource with a !defined as precaution.
    if os_version('debian >= stretch') {
        if !defined(Package['git-lfs']) {
            package { 'git-lfs':
                ensure => present,
            }
        }
    }
}