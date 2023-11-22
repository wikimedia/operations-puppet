# SPDX-License-Identifier: Apache-2.0
# web server hosting https://doc.wikimedia.org
class profile::doc (
    Stdlib::Fqdn        $active_host  = lookup('profile::doc::active_host'),
    Array[Stdlib::Fqdn] $all_hosts    = lookup('profile::doc::all_hosts'),
    Stdlib::Unixpath    $wmf_doc_path = lookup('profile::doc::wmf_doc_path', {'default_value' => '/srv/doc'}),
    Array[Stdlib::Host] $contint_hosts = lookup('jenkins_controller_hosts'),
) {
    include profile::ci::php

    $php_prefix = $profile::ci::php::php_prefix
    $php_version = $profile::ci::php::php_version

    $deploy_user = 'deploy-ci-docroot'

    scap::target { 'integration/docroot':
        deploy_user => $deploy_user,
    }

    ensure_packages(["${php_prefix}-fpm", "${php_prefix}-xml"])

    # The Debian package does not provide a `php-fpm` service and we need scap
    # to be able to restart the service without relying on a version number.
    $restart_cmd = "/bin/systemctl restart ${php_prefix}-fpm"

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
        content  => "Define WMF_DOC_PATH ${wmf_doc_path}\nDefine WMF_DOC_PHP_VERSION ${php_prefix}",
    }

    # Apache configuration for doc.wikimedia.org
    httpd::site { 'doc.wikimedia.org':
        source => 'puppet:///modules/profile/doc/httpd-doc.wikimedia.org.conf'
    }

    profile::auto_restarts::service { "${php_prefix}-fpm": }

    ferm::service { 'doc-http':
        proto  => 'tcp',
        port   => '80',
        srange => '($CACHES $DEPLOYMENT_HOSTS)',
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    systemd::sysuser { 'doc-uploader':
      ensure      => present,
      id          => '922:922',
      description => 'doc-uploader system user',
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

    $is_active = $::fqdn == $active_host
    $ensure_on_active = $is_active.bool2str('present', 'absent')
    $gitlab_runner_hosts = wmflib::role::hosts('gitlab_runner')
    $jenkins_releases_hosts = wmflib::class::hosts('profile::releases::mediawiki')

    file { '/etc/rsync-doc-auth-secrets':
      ensure  => $ensure_on_active,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => secret('doc/secrets'),
    }

    rsync::server::module { 'doc-auth':
        ensure         => $ensure_on_active,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => $gitlab_runner_hosts + $jenkins_releases_hosts,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        auth_users     => ['doc-publisher'],
        secrets_file   => '/etc/rsync-doc-auth-secrets',
        require        => [
            User['doc-uploader'],
            File['/srv/doc'],
            File['/etc/rsync-doc-auth-secrets'],
        ],
    }

    rsync::server::module { 'doc':
        ensure         => $ensure_on_active,
        comment        => 'Docroot of https://doc.wikimedia.org/',
        read_only      => 'no',
        path           => '/srv/doc',
        uid            => 'doc-uploader',
        gid            => 'doc-uploader',
        incoming_chmod => 'D775,F664',
        hosts_allow    => $contint_hosts,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        require        => [
            User['doc-uploader'],
            File['/srv/doc'],
        ],
    }

    rsync::quickdatacopy { 'doc-host-data-sync':
        ensure                     => present,
        source_host                => $active_host,
        dest_host                  => $all_hosts.filter |$host| { $host != $active_host },
        module_path                => '/srv/doc',
        auto_sync                  => true,
        delete                     => true,
        chown                      => 'doc-uploader:doc-uploader',
        auto_interval              => { 'start' => 'OnUnitInactiveSec', 'interval' => '1h' },
        require                    => [User['doc-uploader'], File['/srv/doc']],
        ignore_missing_file_errors => true,
    }

    $all_hosts.each |Stdlib::Fqdn $other_host| {
        prometheus::blackbox::check::http { $other_host:
            server_name        => 'doc.wikimedia.org',
            instance_label     => $other_host,
            team               => 'serviceops-collab',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip4'],
            force_tls          => true,
            body_regex_matches => ['open-source'],
        }
    }
    profile::auto_restarts::service { 'rsync': }

    # We want to _include_ the E_DEPRECATED php logs, T325245
    file { 'php-logging-confd':
        ensure  => present,
        path    => "/etc/php/${php_version}/fpm/conf.d/99-logging-levels",
        owner   => 'root',
        mode    => '0644',
        content => 'error_reporting = E_ALL & ~E_STRICT',
    }

    rsyslog::input::file { 'doc-apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    rsyslog::input::file { 'doc-apache2-access':
        path => '/var/log/apache2/*access*.log',
    }

    rsyslog::input::file { 'doc-phpfpm-error':
        path => '/var/log/php*-fpm.log',
    }

}
