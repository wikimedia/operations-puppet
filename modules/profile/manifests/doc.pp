# web server hosting https://docs.wikimedia.org
class profile::doc {

    scap::target { 'integration/docroot':
        deploy_user => 'deploy-ci-docroot',
    }

    require_package(['php-fpm', 'php-xml'])

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

    # Apache configuration for doc.wikimedia.org
    httpd::site { 'doc.wikimedia.org':
        source => 'puppet:///modules/profile/doc/httpd-doc.wikimedia.org.conf'
    }

    git::clone { 'integration/docroot':
        directory => '/srv/docroot',
        owner     => 'doc-uploader',
        group     => 'doc-uploader',
    }

    ferm::service { 'doc-http':
        proto  => 'tcp',
        port   => '80',
        srange => '($CACHES $DEPLOYMENT_HOSTS)',
    }

    user { 'doc-uploader':
        ensure => present,
        shell  => '/bin/false',
        system => true,
    }
    file { '/srv/docroot/org/wikimedia/doc':
        ensure  => 'directory',
        owner   => 'doc-uploader',
        group   => 'doc-uploader',
        mode    => '0755',
        require => Git::Clone['integration/docroot'],
    }

    backup::set { 'srv-docroot-org-wikimedia-doc': }

    file { '/srv/doc':
        ensure => 'directory',
        owner  => 'doc-uploader',
        group  => 'doc-uploader',
        mode   => '0755',
    }

    # This is to prevent monitoring from alerting. The directory is empty until
    # we have completed the migration of generated documentations. Once done,
    # we should remove the file.
    file { '/srv/doc/BACKMEUP':
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'Placeholder for Bacula',
    }

    backup::set { 'srv-doc': }

    class { '::rsync::server': }

    rsync::server::module { 'doc':
        ensure         => present,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/docroot/org/wikimedia/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => ['contint1001.wikimedia.org', 'contint2001.wikimedia.org'],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        require        => [
            User['doc-uploader'],
            File['/srv/docroot/org/wikimedia/doc'],
        ],
    }

    base::service_auto_restart { 'rsync': }
}
