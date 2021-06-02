# == Class profile::analytics::cluster::packages::statistics
#
# Specific packages that should be installed on analytics statistics
# nodes (no Hadoop client related packages).
#
class profile::analytics::cluster::packages::statistics {

    include ::profile::analytics::cluster::packages::common

    class { '::imagemagick::install': }

    require_package([
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
        'libbz2-dev',             # For compiling some python libs. T84378
        'libboost-regex-dev',     # Ironholds wants these
        'libboost-system-dev',
        'libgoogle-glog-dev',
        'libboost-iostreams-dev',
        'libmaxminddb-dev',
        'build-essential',        # Requested by halfak to install SciPy
        'libssl-dev',             # Requested by bearloga; necessary for an essential R package {openssl}
        'libcurl4-openssl-dev',   # Requested by bearloga for an essential R package {devtools}
        'libicu-dev',             # ^
        'libssh2-1-dev',          # ^
        'pandoc',                 # Requested by bearloga for using RMarkdown and performing format conversions
        'pandoc-citeproc',        # ^
        'lynx',                   # Requested by dcausse to be able to inspect yarn's logs from analytics10XX hosts
        'gsl-bin',
        'libgsl-dev',
        'libgdal-dev',            # Requested by lzia for rgdal
        'g++',
        'libyaml-cpp-dev',        # Latest version of uaparser (https://github.com/ua-parser/uap-r) supports v0.5+
        'php-cli',
        'php-curl',
        'php-mysql',
        'libfontconfig1-dev',     # For {systemfonts} R pkg dep of {hrbrthemes} pkg for dataviz (T254278)
        'libcairo2-dev',          # ^
    ])

    require_package([
        # For embedded configurable-http-proxy
        'nodejs',
        'npm',
        'libgslcblas0',
        'mariadb-client-10.3',
        'libyaml-cpp0.6',
        # Python packages
        'virtualenv',
        'libapache2-mod-python',
        'python3-mock',
        'python3-virtualenv',        # T84378
        'python3-venv',
        'python3-dev',               # T83316
    ])

    # FORTRAN packages (T89414)
    require_package([
        'gfortran',        # GNU Fortran 95 compiler
        'liblapack-dev',   # FORTRAN library of linear algebra routines
        'libopenblas-dev', # Optimized BLAS (linear algebra) library
    ])

    # scap also deploys git-lfs to clients, so guarding
    # the package resource with a !defined as precaution.
    if !defined(Package['git-lfs']) {
        package { 'git-lfs':
            ensure => present,
        }
    }
}
