# web server hosting https://docs.wikimedia.org
class profile::doc {

    $php_version='7.2'
    $php_package="php${php_version}-fpm"

    # Use php7.2 from Ondrej Sury's repository.
    if $php_version == '7.2' {

        exec {'apt_update_php':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
        }

        apt::repository { 'wikimedia-php72':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/php72',
            notify     => Exec['apt_update_php'],
            before     => Package[$php_package]
        }
    }

    require_package($php_package)

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_fcgi'],
    }

    class { '::httpd::mpm':
        mpm    => 'worker',
        source => 'puppet:///modules/profile/files/doc/httpd_worker.conf'
    }

    ferm::service { 'doc-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
