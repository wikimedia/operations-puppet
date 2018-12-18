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
        }

        package { $php_package:
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

    file { [
        '/srv/org',
        '/srv/org/wikimedia/',
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0755',
    }

    user { 'doc-uploader':
        ensure => present,
        shell  => '/bin/false',
        system => true,
    }
    file { '/srv/org/wikimedia/doc':
        ensure => 'directory',
        owner  => 'doc-uploader',
        group  => 'wikidev',
        mode   => '0755',
    }

    backup::set { 'srv-org-wikimedia': }

    class { '::rsync::server': }

    rsync::server::module { 'doc':
        ensure         => present,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/org/wikimedia/doc',
        uid            => 'doc-uploader',
        gid            => 'wikidev',
        hosts_allow    => ['contint1001.wikimedia.org', 'contint2001.wikimedia.org'],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        require        => [
            User['doc-uploader'],
            File['/srv/org/wikimedia/doc'],
        ],
    }

}
