# = Class: statistics::packages
# Various packages useful for statistics crunching on stat-type hosts
class statistics::packages {
    include ::geoip
    include ::imagemagick::install

    require_package([
        'time',
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
    ])


    # TODO: remove after T152712
    # If available, install openjdk-7-jdk

    if os_version('debian >= stretch') {
        require_package(
            'libgsl2',
            'gsl-bin',
            'libgsl0-dev',
            'libgdal-dev',      # Requested by lzia for rgdal
            'g++',
            'libyaml-cpp-dev',  # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
            'libyaml-cpp0.5v5', # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
            'php-cli',
            'php-curl',
            'php-mysql',
            'mariadb-client-10.1',
        )
    }

    else {
        require_package(
            'openjdk-7-jdk',
            'libgsl0ldbl',
            'gsl-bin',
            'libgsl0-dev',
            # Requested by bearloga to ensure that there is a compiler with C++11
            # support that can compile R package 'Boom'; see T147682 and
            # http://stackoverflow.com/a/36034866/1091835 for more info)
            'g++-4.8',
            'gfortran-4.8',
            'libgdal1-dev',       # Requested by lzia for rgdal
            'libyaml-cpp0.3-dev', # Requested by Ironholds (old version of uaparser requires v0.3)
            'libyaml-cpp0.3',     # Requested by Ironholds (old version of uaparser requires v0.3)
            'php5-cli',
            'php5-curl',
            'php5-mysql',
            'mysql-client-5.5',
        )
    }

    # Python packages
    require_package ([
        'python-geoip',
        'libapache2-mod-python',
        'python-mysqldb',
        'python-yaml',
        'python-dateutil',
        'python-numpy',
        'python-scipy',
        'python-boto',       # Amazon S3 access (needed to get zero sms logs)
        'python-pandas',     # Pivot tables processing
        'python-requests',   # Simple lib to make API calls
        'python-unidecode',  # Unicode simplification - converts everything to latin set
        'python-ua-parser',  # For parsing User Agents
        'python-matplotlib', # For generating plots of data
        'python-netaddr',
        'python-virtualenv', # T84378

        # Aaron Halfaker (halfak) wants python{,3}-dev environments for module oursql
        'python-dev',        # T83316
        'python3-dev',       # T83316
        'python-kafka',
        'python-pymysql',
    ])

    if os_version('debian >= jessie') {
        require_package([
            'virtualenv',
        ])
    }

    # This is a custom package and currently not available on jessie, don't install on jessie for now
    if os_version('ubuntu >= trusty') {
        require_package([
            'python-pygeoip', # For geo-encoding IP addresses
        ])
    }

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



    # Use R from Jessie Backports on jessie boxes.
    if os_version('debian == jessie') {
        $r_packages = [
            'r-base',
            'r-base-dev',      # Needed for R packages that have to compile C++ code; see T147682
            'r-cran-rmysql',
            'r-recommended'    # CRAN-recommended packages (e.g. MASS, Matrix, boot)
        ]

        # Explicitly list package dependencies, instead of using require_package,
        # to avoid dependency issues with the 'before' clause in apt::pin.
        package { $r_packages:
            ensure => present,
        }

        apt::pin { $r_packages:
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package[$r_packages],
        }
    }

    else {
        include ::r_lang
        require_package('r-cran-rmysql') # Note: RMariaDB (https://github.com/rstats-db/RMariaDB) will replace RMySQL, but is currently not on CRAN
    }

    if os_version('ubuntu >= trusty') {
        # A lot of these packages don't exist on debian yet,
        # and notebook* hosts are on debian. Let's just not install these
        # on debian for now.
        # spell checker/dictionary packages for research (halfak)
        # T99030 - for machine learning and natural language processing
        # T121011 - for vandalism detection
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
            'myspell-en-us', # English_american dictionary for myspell
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
            'myspell-nr', # The Ndebele dictionary for myspell
            'myspell-ns', # Northern Sotho dictionary for myspell
            'myspell-pl', # Polish dictionary for myspell
            'myspell-pt-br', # Brazilian Portuguese dictionary for myspell
            'myspell-pt', # Portuguese dictionaries for myspell
            'myspell-pt-pt', # European Portuguese dictionary for myspell
            'myspell-ru', # Russian dictionary for MySpell
            'myspell-sk', # Slovak dictionary for myspell
            'myspell-sl', # Slovenian dictionary for myspell
            'myspell-ss', # The Swazi dictionary for myspell
            'myspell-st', # The Southern Sotho dictionary for myspell
            'myspell-sv-se', # transitional dummy package
            'myspell-sw', # Swahili dictionary for myspell
            'myspell-th', # Thai dictionary for myspell
            'myspell-tl', # Tagalog dictionary for myspell/hunspell
            'myspell-tn', # The Tswana dictionary for myspell
            'myspell-ts', # The Tsonga dictionary for myspell
            'myspell-uk', # Ukrainian dictionary for myspell
            'myspell-ve', # The Venda dictionary for myspell
            'myspell-xh', # The Xhosa dictionary for myspell
            'myspell-zu', # The Zulu dictionary for myspell
        ])
    }
    elsif os_version('debian >= stretch') {
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
    }
}
