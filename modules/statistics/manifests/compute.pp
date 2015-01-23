# == Class statistics::compute
# Class containing common stuff for a statisitics compute node.
#
class statistics::compute {
    Class['::statistics'] -> Class['::statistics::compute']

    # include mysql module base class to install mysql client
    include mysql
    include geoip
    include statistics::dataset_mount

    include misc::udp2log::udp_filter

    require_package('nodejs')
    require_package('openjdk-7-jdk')

    package { [
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
        'libbz2-dev', # for compiling some python libs.  RT 8278
        'libboost-regex-dev',  # Ironholds wants these
        'libboost-system-dev',
        'libyaml-cpp0.3',
        'libyaml-cpp0.3-dev',
        'libgoogle-glog-dev',
        'libboost-iostreams-dev',
        'libmaxminddb-dev',
        'build-essential', # Requested by halfak to install SciPy
    ]:
        ensure => 'latest',
    }

    # Python packages
    package { [
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
        'python-dev',  # RT 6561
        'python3-dev', # RT 6561
    ]:
        ensure => 'installed',
    }

    # Plotting packags
    package { [
        'ploticus',
        'libploticus0',
        'r-base',
        'r-cran-rmysql',
        'libcairo2',
        'libcairo2-dev',
        'libxt-dev'
    ]:
        ensure => installed,
    }

    # clones mediawiki core at $working_path/mediawiki/core
    # and ensures that it is at the latest revision.
    # RT 2162
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
    # /etc/mysql/conf.d/research-client.cnf.
    mysql::config::client { 'research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'researchers',
        mode  => '0440',
    }
    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    mysql::config::client { 'stats-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $::statistics::user::username,
        mode  => '0440',
    }
}
