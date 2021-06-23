# This class sets up a node as an execution environment for Toolforge.
#

class profile::toolforge::grid::exec_environ::stretch {

    package { [
        'gcj-jdk',                   # T58995
        'gcj-jre',                   # T58995
        'libav-tools',               # T55870.
        'libdmtx0a',                 # T55867.
        'libmpfr4',
        'mono-vbnc',                 # T186846
        'ttf-ubuntu-font-family',    # T32288, T103325 from stretch-wikimedia
    ]:
        ensure => latest,
        before => Class['profile::locales::all'],
    }

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

    # T67354, T215693 - Tesseract OCR from our custom backport
    $tesseract_packages = [
        'tesseract-ocr-all',
        'tesseract-ocr',
        'libtesseract4',
    ]
    apt::package_from_component { 'tesseract':
        component => 'component/tesseract-410-bpo',
        distro    => 'stretch-wikimedia',
        packages  => $tesseract_packages,
    }

    # T248376 - {python,python3}-requests from stretch-backports
    $requests_packages = [
        'python-requests',
        'python3-requests',
    ]
    apt::pin { $requests_packages:
        pin      => 'release a=stretch-backports',
        priority => '2000',
        before   => Package[$requests_packages],
    }
    package { $requests_packages:
        ensure          => latest,
        install_options => ['-t', 'stretch-backports'],
    }


    package { [
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
        'php-igbinary',                # T262186
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

    # Setup some reasonable defaults for PHP
    $php_config_dir = '/etc/php/7.2'
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
        require => Package['php7.2-cli'],
    }
}
