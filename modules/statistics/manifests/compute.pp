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
    ])

    # FORTRAN packages (T89414)
    ensure_packages([
        'gfortran',        # GNU Fortran 95 compiler
        'liblapack-dev',   # FORTRAN library of linear algebra routines
        'libopenblas-dev', # Optimized BLAS (linear algebra) library
    ])

    # Plotting packags
    ensure_packages([
        'ploticus',
        'libploticus0',
        'r-base',
        'r-cran-rmysql',
        'libcairo2',
        'libcairo2-dev',
        'libxt-dev'
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
}
