# web server hosting https://doc.wikimedia.org
class profile::doc (
    Stdlib::Unixpath $wmf_doc_path = lookup('profile::doc::wmf_doc_path', {'default_value' => '/srv/doc'}),
) {

    $deploy_user = 'deploy-ci-docroot'

    scap::target { 'integration/docroot':
        deploy_user => $deploy_user,
    }

    $php = 'php7.0'

    ensure_packages(["${php}-fpm", "${php}-xml"])

    $restart_cmd = "/bin/systemctl restart ${php}-fpm"

    # scap deployment swap symlink which confuses PHP opcache. On promote
    # stage, scap invoke this script to clear the opcache.
    file { '/usr/local/sbin/restart-php-fpm-unsafe':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => "#!/bin/bash\nexec sudo -u root -- ${restart_cmd}\n"
    }

    sudo::user { 'deploy_restart_fpm':
        user       => $deploy_user,
        privileges => ["ALL = NOPASSWD: ${restart_cmd}"],
    }

    class { '::httpd':
        modules => ['setenvif',
                    'headers',
                    'rewrite',
                    'proxy',
                    'proxy_fcgi'],
    }

    class { '::httpd::mpm':
        mpm    => 'worker',
        source => 'puppet:///modules/profile/doc/httpd_worker.conf'
    }

    httpd::conf { 'wmf_doc_path':
        priority => 40,
        content  => "Define WMF_DOC_PATH ${wmf_doc_path}",
    }

    # Apache configuration for doc.wikimedia.org
    httpd::site { 'doc.wikimedia.org':
        source => 'puppet:///modules/profile/doc/httpd-doc.wikimedia.org.conf'
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
        path           => '/srv/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => ['contint1001.wikimedia.org', 'contint2001.wikimedia.org'],
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        require        => [
            User['doc-uploader'],
            File['/srv/doc'],
        ],
    }

    base::service_auto_restart { 'rsync': }
}
