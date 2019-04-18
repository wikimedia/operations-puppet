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
        'gsl-bin',
        'libgsl-dev',
        'libgdal-dev',      # Requested by lzia for rgdal
        'g++',
        'libyaml-cpp-dev',  # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
        'php-cli',
        'php-curl',
        'php-mysql',
    ])

    if os_version('debian >= buster') {
        require_package([
            'libgslcblas0',
            'mariadb-client-10.3',
            'libyaml-cpp0.6',
        ])
    } else {
        require_package([
            'libgsl2',
            'mariadb-client-10.1',
            'libyaml-cpp0.5v5',
        ])
    }

    # Python packages
    require_package ([
        'virtualenv',
        'libapache2-mod-python',
        'python-mysqldb',               'python3-mysqldb',
        'python-boto',                  'python3-boto',  # Amazon S3 access (to get zero sms logs)
                                        'python3-ua-parser',
        'python-netaddr',               'python3-netaddr',
        'python-pymysql',               'python3-pymysql',
        'python-virtualenv',            'python3-virtualenv', # T84378
                                        'python3-venv',
        'python-dev',                   'python3-dev',        # T83316
        'python-protobuf',              'python3-protobuf',
        'python-unidecode',             'python3-unidecode',
        'python-oauth2client',          'python3-oauth2client',         # T197896
        'python-oauthlib',              'python3-oauthlib',             # T197896
        'python-requests-oauthlib',     'python3-requests-oauthlib',    # T197896
    ])


    # These packages need to be reviewed in the context of Debian Buster
    # to figure out if we need to rebuild them or simply copy them over in reprepro.
    if os_version('debian <= stretch') {
        require_package([
            # WMF maintains python-google-api at
            # https://gerrit.wikimedia.org/r/#/admin/projects/operations/debs/python-google-api
            'python-google-api',
            'python3-google-api', # T190767
            'python-ua-parser',
        ])
    }


    # FORTRAN packages (T89414)
    require_package([
        'gfortran',        # GNU Fortran 95 compiler
        'liblapack-dev',   # FORTRAN library of linear algebra routines
        'libopenblas-dev', # Optimized BLAS (linear algebra) library
    ])

    # These packages need to be reviewed in the context of Debian Buster
    # to figure out if we need to rebuild them or simply copy them over in reprepro.
    if os_version('debian <= stretch') {
        # Plotting packages
        require_package([
            'ploticus',
            'libploticus0',
            'libcairo2',
            'libcairo2-dev',
            'libxt-dev',
        ])
    }

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
    if os_version('debian <= stretch') {
        if !defined(Package['git-lfs']) {
            package { 'git-lfs':
                ensure => present,
            }
        }
    }
}