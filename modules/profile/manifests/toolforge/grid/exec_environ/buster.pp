# This class sets up a node as an execution environment for Toolforge.
#

class profile::toolforge::grid::exec_environ::buster {
    package { [
        # Commented packages are not currently available
        #'gcj-jdk',                   # T58995
        #'gcj-jre',                   # T58995
        #'libav-tools',               # T55870.
        #'libdmtx0a',                 # T55867.
        #'libmpfr4',
        #'mono-vbnc',                 # T186846 from stretch-wikimedia/thirdparty/mono-project-stretch
        #'ttf-ubuntu-font-family',    # will not be available, non-free
        'node-cacache',
        'node-gyp',
        'node-move-concurrently',
        'nodejs',
        'libnode-dev',
        'npm',
        'python-requests',
        'python3-requests',
        'libboost-python-dev',          # T213965
        'libmpc3',
        #'libproj12',
        #'libprotobuf10',
        'libbytes-random-secure-perl', # T123824
        'libvips42',
        'mariadb-client',              # For /usr/bin/mysql
        'libpng16-16',
        #'perl-modules-5.24',
        # PHP libraries (Buster is on php7.3)
        'php-apcu',
        'php-apcu-bc',
        'php7.3-bcmath',
        'php7.3-bz2',
        'php7.3-cli',
        'php7.3-common',
        'php7.3-curl',
        'php7.3-dba',
        'php7.3-gd',
        'php-imagick',                # T71078.
        'php7.3-intl',                   # T57652
        'php7.3-mbstring',
        # php-mcrypt is deprecated on 7.1+
        'php7.3-mysql',
        'php7.3-pgsql',                  # For access to OSM db
        'php7.3-readline',               # T136519.
        'php-redis',
        'php7.3-soap',
        'php7.3-sqlite3',
        'php-xdebug',                 # T72313
        # php-xhprof isn't available in buster
        'php7.3-xml',
        'php7.3-zip',
        'php-igbinary',                # T262186
        'opencv-data',                 # T142321
        'openjdk-11-jre-headless',
        'tesseract-ocr-all',           # T67354, T215693 - Tesseract OCR
        'tesseract-ocr',
        'libtesseract4',
        'tcl-thread',
        'libmariadbclient-dev',
        #'libmariadbclient-dev-compat',
        #'libboost1.62-dev',
        'libboost-dev',
        'libkml-dev',
        'libgdal-dev',                # T58995
        #'libboost-python1.62-dev',
        'openjdk-11-jdk',
        'libpng-dev',
        'libtiff5-dev',  # T54717
        'tcl-dev',
    ]:
        ensure => latest,
        before => Class['profile::locales::all'],
    }

    include ::profile::toolforge::genpp::python_exec_buster


    # Setup some reasonable defaults for PHP
    $php_config_dir = '/etc/php/7.3'
    $php_config = {
        'date'                   => {
            'timezone' => 'UTC',
        },
        'default_socket_timeout' => 1,
        'memory_limit'           => '4G',
        'mysql'                  => {
            'connect_timeout'  => 1,
            'allow_persistent' => 0,
        },
    }
    file { "${php_config_dir}/cli/php.ini":
        ensure  => present,
        content => php_ini($php_config, {}),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php7.3-cli'],
    }
}
