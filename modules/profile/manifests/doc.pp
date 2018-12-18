# web server hosting https://docs.wikimedia.org
class profile::doc {

    $php_version='7.2'
    $php_package="php${php_version}-fpm"

    # Use php7.2 from Ondrej Sury's repository.
    if $php_version == '7.2' {

        apt::repository { 'wikimedia-php72':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/php72',
            notify     => Exec['apt_update_php'],
        }

        package { '$php_package':
            ensure  => installed,
            require => [ Apt::Repository['wikimedia-php72'],
                        Exec['apt-get update']],
        }
    }

    class { '::httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_fcgi'],
    }

    class { '::httpd::mpm':
        mpm    => 'worker',
        source => 'puppet:///modules/profile/doc/httpd_worker.conf'
    }

    ferm::service { 'doc-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
