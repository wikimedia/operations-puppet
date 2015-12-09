# == Class statistics::compute
# Class containing common stuff for a statisitics compute node.
#
class statistics::compute {
    Class['::statistics']       -> Class['::statistics::compute']
    Class['::statistics::user'] -> Class['::statistics::compute']


    # include mysql module base class to install mysql client
    include mysql
    include geoip
    include statistics::dataset_mount

    include misc::udp2log::udp_filter

    ensure_packages([
        'emacs23',
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'subversion',
        'mercurial',
        'tofrodos',
        'git-review',
        'imagemagick',
        # halfak wants make to manage dependencies
        'make',
        # for checking up on eventlogging
        'zpubsub',
        # libwww-perl for wikistats stuff
        'libwww-perl',
        'php5-cli',
        'php5-curl',
        'php5-mysql',
        'sqlite3', # For storing and interacting with intermediate results
        'libgdal1-dev', # Requested by lzia for rgdal
        'libproj-dev', # Requested by lzia for rgdal
        'libbz2-dev', # for compiling some python libs. T84378
        'libboost-regex-dev',  # Ironholds wants these
        'libboost-system-dev',
        'libyaml-cpp0.3',
        'libyaml-cpp0.3-dev',
        'libgoogle-glog-dev',
        'libboost-iostreams-dev',
        'libmaxminddb-dev',
        'build-essential', # Requested by halfak to install SciPy
        'nodejs',
        'openjdk-7-jdk'
    ])

    # Python packages
    ensure_packages ([
        'python-geoip',
        'libapache2-mod-python',
        'python-django',
        'python-mysqldb',
        'python-yaml',
        'python-dateutil',
        'python-numpy',
        'python-scipy',
        'python-boto',      # Amazon S3 access (needed to get zero sms logs)
        'python-pandas',    # Pivot tables processing
        'python-requests',  # Simple lib to make API calls
        'python-unidecode', # Unicode simplification - converts everything to latin set
        'python-pygeoip',   # For geo-encoding IP addresses
        'python-ua-parser', # For parsing User Agents
        'python-matplotlib',  # For generating plots of data
        'python-netaddr',
        'python-virtualenv', # T84378
        # Aaron Halfaker (halfak) wants python{,3}-dev environments for module oursql
        'python-dev',  # T83316
        'python3-dev', # T83316
        'python-kafka',
    ])

    # FORTRAN packages (T89414)
    ensure_packages([
        'gfortran',        # GNU Fortran 95 compiler
        'liblapack-dev',   # FORTRAN library of linear algebra routines
        'libopenblas-dev', # Optimized BLAS (linear algebra) library
    ])

    # Plotting packages
    ensure_packages([
        'ploticus',
        'libploticus0',
        'r-base',
        'r-cran-rmysql',
        'libcairo2',
        'libcairo2-dev',
        'libxt-dev'
    ])

    # spell checker/dictionary packages for research (halfak)
    # T99030 - for machine learning and natural language processing
    # T121011 - for vandalism detection
    ensure_packages([
        'enchant', # generic spell checking library (uses myspell as backend)
        'aspell-id',   # Indonesian dictionary for GNU aspell
        'hunspell-vi', # Vietnamese dictionary for hunspell
        'myspell-af', # Afrikaans dictionary for myspell
        'myspell-bg', # Bulgarian dictionary for myspell
        'myspell-ca', # Catalan dictionary for myspell
        'myspell-cs', # Czech dictionary for myspell
        'myspell-da', # The Comprehensive Danish Dictionary (DSDO)
        'myspell-de-at', # Austrian (German) dictionary for myspell
        'myspell-de-ch', # Swiss (German) dictionary for myspell
        'myspell-de-de', # German dictionary for myspell
        'myspell-de-de-oldspell', # German dictionary for myspell (old orthography)
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
        'myspell-nb', # Norwegian Bokmål dictionary for myspell
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

    # clones mediawiki core at $working_path/mediawiki/core
    # and ensures that it is at the latest revision.
    # T80444
    $statistics_mediawiki_directory = "${::statistics::working_path}/mediawiki/core"

    git::clone { 'statistics_mediawiki':
        ensure    => 'latest',
        directory => $statistics_mediawiki_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
        owner     => 'mwdeploy',
        group     => 'wikidev',
    }

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    mysql::config::client { 'stats-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $::statistics::user::username,
        mode  => '0440',
    }

    # Clean up R temporary files which have not been accessed in a week.
    tidy { '/tmp':
        matches => 'Rtmp*',
        age     => '1w',
        rmdirs  => true,
        backup  => false,
        recurse => 1,
    }
}
